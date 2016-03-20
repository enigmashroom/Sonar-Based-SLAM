function [f,fopts,data] = PicoFLSRead(f,varargin)

% Initialise data and file format options
if ~isempty(varargin)
    data = varargin{2};
    fopts = varargin{1};
    
else
    data = [];
    
    % Find the mystery sequence in the data
    nmystery = 1000000;
    dmystery = [229 59 192 81 6 0 2 0];
    d = fread(f,nmystery,'uchar',0,'ieee-le');    
    I = strfind(d.',dmystery);
    if ~isempty(I)
        fopts.mystery.period = I(2)-I(1);
        fopts.mystery.n0 = I(1);
    end
    
    % Could also use matched filter to find first PDU index
    
    % Reset file pointer
    frewind(f)
    fopts.nread = 0; % Number of octets read
    
    % Skip to beginning of first mystery sequence
    if isfield(fopts,'mystery')
        d = fread(f,fopts.mystery.n0-1,'uchar',0,'ieee-le');
        fopts.nread = fopts.mystery.n0-1;
    end
end


% Initialise frame index
previndex = -1;

while 1
    
    % Skip the mystery sequence
    if isfield(fopts,'mystery')
        if ((fopts.nread+1)==fopts.mystery.n0) | ...
                ~mod(fopts.nread-fopts.mystery.n0+1,fopts.mystery.period)
            d = fread(f,1312,'uchar',0,'ieee-le');
            fopts.nread = fopts.nread + 1312;
        end
    end
    
    % Read frame index
    index = fread(f,1,'uint32',0,'ieee-le');
    fopts.nread = fopts.nread + 4;
    
    % Check for end of file
    if feof(f)
        data = [];
        break
    end
    
    % Check for end of ping
    if index < previndex
        fseek(f,-4,0);
        fopts.nread = fopts.nread - 4;
        break;
    end
    
    previndex = index;
    
    % Read frame data
    d = fread(f,512,'uchar',0,'ieee-le');
    fopts.nread = fopts.nread + 512;
    
    d = reshape(d,[64,8]);
    
    % Beam indices
    beams = mod(index,8) * 8 + [1:8];
    
    % Time sample indices
    times = floor(index/8)*64 + [1:64];
    
    % Populate ping data
    data(times,beams) = d;
    
end


% +-------+-------+--------------+-----------+-----------------------+
% | Byte  | Num   |   Encoding   |   Item    |        Notes          |
% | Num   | Bytes |              |           |                       |
% +-------+-------+--------------+-----------+-----------------------+
% |   0   |   4   | unsigned int |  Index    | PDU Index.            |
% +-------+-------+--------------+-----------+-----------------------+
% |   4   |  64   | unsigned char|  Magnitude| Beam i magnitude.     |
% |  68   |  64   | unsigned char|  Magnitude| Beam i+1 magnitude.   |
% | 132   |  64   | unsigned char|  Magnitude| Beam i+2 magnitude.   |
% | 196   |  64   | unsigned char|  Magnitude| Beam i+3 magnitude.   |
% | 260   |  64   | unsigned char|  Magnitude| Beam i+4 magnitude.   |
% | 324   |  64   | unsigned char|  Magnitude| Beam i+5 magnitude.   |
% | 388   |  64   | unsigned char|  Magnitude| Beam i+6 magnitude.   |
% | 452   |  64   | unsigned char|  Magnitude| Beam i+7 magnitude.   |
% +-------+-------+--------------+-----------+-----------------------+
%
% Notes:
% 1/ Little-endian, least significant byte first.
% 2/ PDU size is 516 octets.
% 3/ Emitted @ 6.25kHz*rate, rate=1,1/2,1/4,1/8, sampled at 50kHz
% 4/ Index is reset to zero at the start of each ping.
% 5/ Beam i=mod(Index,8)*8

% Diver dataset:
% - 512 indices per ping

% Shipwreck dataset:
% - 1024 indices per ping; 
% - 36 octets between frames;
% - Does not start on PDU index
% - Mystery sequence of 1312 uchars between each ping

% Each index --> 64 samples from 8 beams
% 8 indices --> 64 samples from 64 beams
% 512 indices --> 4096 samples from 64 beams
% 1024 indices --> 8096 samples from 64 beams
