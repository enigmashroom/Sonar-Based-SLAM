close all


%filename = 'PicoFLS_vs_Diver.dat';
filename = 'PicoFLS_OB15.dat';


% Nf=2000;                              % Set the number of frames
% Mq=moviein  (Nf);                   % Mq is the movie

% Image dimensions
switch filename
    case 'PicoFLS_vs_Diver.dat'
        Lx = 9;
        Ly = 12;
        nx = 768;
        ny = 1024;
    case 'PicoFLS_OB15.dat'
        Lx = 50;
        Ly = 100;
        nx = 512;
        ny = 1024;
end

% Image axes
x = [-nx/2:nx/2-1]/nx * Lx;
y = [0:ny-1]/ny * Ly;
[xrep,yrep] = meshgrid(x,y);
ri = sqrt(xrep.^2+yrep.^2);
thetai = atan(xrep./yrep);

% Speed of sound
c = 1500;

% Temporal sampling frequency
fs = 50e3;

% Angle axis
dtheta = 0.7 * pi/180;


% Read from file
f = fopen(filename,'r');

n=1;
while ~feof(f)
    n;
    
    % Read a frame
    if n==1
        [f,fopts,data] = PicoFLSRead(f);
        
        % Initialise time and angle axes
        [nt,ntheta] = size(data);
        t = [0:nt-1] / fs;
        theta = [-ntheta/2:ntheta/2-1] * dtheta;
    else
        [f,fopts,data] = PicoFLSRead(f,fopts,data);
    end
    
    % No more frames
    if isempty(data)
        break
    end
    
    % Map time-angle data to image frame
    im = interp2(theta,t*c/2,data/255,thetai,ri,'*linear',NaN);
    
    figure(1)
    mesh(y,x,20*log10(im.'));
%     imagesc(y,x,20*log10(im.'))
    axis equal
    colormap(gray)
    caxis([-25 -5])
    title(['Frame ' num2str(n)])
    
    
    s = ['Frame_' num2str(n)];
%     saveas(gcf,s,'tiffn');
%     saveas(gcf,s,'png');
%     savefig(s);
%     save
%     Mq(:,n)=getframe;
%     
    pause
%     pause(0.1)
    n=n+1;
end
% movie(Mq);
% movie2avi(Mq,'enigma.avi');
fclose(f);
