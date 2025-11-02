%% digital func
% Parámetros del sistema continuo
K = 0.7978;
tau = 0.1200;
delay = 0.0300;
fo_sys = tf([K], [tau 1],'InputDelay',delay);

% Tiempo de muestreo
ts = 0.01;

% Discretización usando ZOH y Tustin
Hz1 = c2d(fo_sys, ts, 'zoh');
Hz2 = c2d(fo_sys, ts, 'tustin');

% Simulación de la respuesta al escalón
T = 0:0.001:1;         % Vector de tiempo fino para la señal continua
t_discrete = 0:ts:1;    % Vector de tiempo para las señales discretas

% Respuesta al escalón del sistema continuo
[y_cont, t_cont] = step(fo_sys, T);

% Respuesta al escalón del sistema discreto (ZOH)
[y_disc1, t_disc1] = step(Hz1, t_discrete);
% Interpolar la respuesta discreta para que tenga la misma longitud que la continua
y_disc1_interp = interp1(t_disc1, y_disc1, t_cont, 'previous', 0);

% Respuesta al escalón del sistema discreto (Tustin)
[y_disc2, t_disc2] = step(Hz2, t_discrete);
% Interpolar la respuesta discreta para que tenga la misma longitud que la continua
y_disc2_interp = interp1(t_disc2, y_disc2, t_cont, 'previous', 0);

% Calcular el RMSE
rmse_zoh = sqrt(mean((y_cont - y_disc1_interp).^2));
rmse_tustin = sqrt(mean((y_cont - y_disc2_interp).^2));

fprintf('RMSE (ZOH): %.4f\n', rmse_zoh);
fprintf('RMSE (Tustin): %.4f\n', rmse_tustin);

if rmse_zoh < rmse_tustin
    mejor_metodo = 'ZOH';
    menor_rmse = rmse_zoh;
else
    mejor_metodo = 'Tustin';
    menor_rmse = rmse_tustin;
end


% Graficar las respuestas
figure;
plot(t_cont, y_cont, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Continuous');
hold on;
stairs(t_disc1, y_disc1, 'k:', 'LineWidth', 1.5, 'DisplayName', 'Discrete (ZOH)');
stairs(t_disc2, y_disc2, 'k-', 'LineWidth', 1.5, 'DisplayName', 'Discrete (Tustin)');
xlabel('Time [s]');
ylabel('Shaft speed[RPM]');
legend('FontSize', 10, 'Location', 'best');
grid on;
grid minor; % Añadir líneas de cuadrícula menores para mejor legibilidad en B/N
ax = gca;
ax.FontSize = 10;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
hold off;
%% controller
% Parámetros del sistema continuo
K = 0.7978;
ts = 0.01;
tau = 0.1200;
delay = 0.0300;
fo_sys = tf([K], [tau 1],'InputDelay',delay);
Hz = c2d(fo_sys, ts, 'tustin');
fo_d=tf([1],[0.12*0.9 1])

desired=c2d(fo_d,ts,'zoh').denominator{1}
[r,s,t]=incremental_rst(Hz,4,desired,ts)
%% sim
simData=out
t = simData.simout.Time;    % Time vector
y = simData.simout.Data(:,1);  % First signal
u = simData.simout.Data(:,2);  % Second signal (adjust index if needed)
sp = simData.simout.Data(:,3);
%sp = simData.simout.Data(:,3);
% Create the figure
figure;
hold on;
xlabel('Time (s)','FontSize',14);
ylabel('RPM','FontSize',14);
plot(t, y, 'k-', 'LineWidth', 1.5);        % Línea continua azul para la temperatura
%plot(t, sp, 'K:', 'LineWidth', 1.5);       % Línea continua verde para el set-point
plot(t, sp, 'k--', 'LineWidth', 1.5);
%plot(t,u, 'k', 'LineWidth', 1.5);% Removido, pero se puede agregar con estilo si es necesario
%legend('RPM','Set-point','FontSize',12);
legend('RPM','Set-point','FontSize',12);% Modificado el texto de la leyenda
grid on;
grid minor;
% Establecer los límites del eje x para que coincidan con el vector de tiempo
xlim([min(t),max(t)]);
ylim([0,50])
ax = gca;
ax.FontSize = 12;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
hold off;