% File names
archivos = {'30_input.csv', '40_input.csv', '50_input.csv', '60_input.csv'};
% Corresponding U values
valores_U = [30, 40, 50, 60];
% Store the obtained transfer functions
funciones_transferencia = cell(length(archivos), 1);
% Colors for each graph (more distinct and lighter) for the first plot
colores_datos_fig1 = {'#1f77b4', '#2ca02c', '#9467bd', '#e377c2'}; % Blue, Green, Purple, Pink
colores_simulacion_fig1 = {'#aec7e8', '#98df8a', '#c5b0d5', '#f7b6d2'}; % Lighter versions

% Colors for the second plot (different from the first)
colores_datos_fig2 = {'#d62728', '#ff7f0e', '#8c564b', '#e377c2'}; % Red, Orange, Brown, Pink
colores_simulacion_fig2 = {'#ff9896', '#ffbb78', '#c49c94', '#f7b6d2'}; % Lighter versions


% --- End of placeholder ---

% Iterate through each file to obtain the transfer functions
for i = 1:length(archivos)
    nombre_archivo = archivos{i};
    valor_U = valores_U(i);
    datos = csvread(nombre_archivo, 1, 0);
    t = datos(:, 1)/1000; % Convert time to seconds
    Y = datos(:, 2);
        % Create the U vector with the corresponding constant value
    U = ones(length(t), 1) * valor_U;
    po_tf = fo_aprox(Y,U, t); % Assuming fo_aprox does not use U directly
    funciones_transferencia{i} = po_tf;
    disp(['Transfer Function for ', nombre_archivo, ' (U=', num2str(valor_U), '):']);
    disp(po_tf);
    disp(' ');
end

% --- First Figure: Plot the temporal response of each transfer function compared to the real data ---
figure;
hold on; % Keep the current graph to superimpose the following
xlabel('Time [s]'); % X-axis in seconds
ylabel('Shaft speed [RPM]');
grid on;
grid minor; % Añadir líneas de cuadrícula menores para mejor legibilidad en B/N
ax = gca;
ax.FontSize = 10;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
line_styles_real = {'-', '--', ':', '-.'}; % Estilos para datos reales
line_styles_sim = {':', '-.', '-', '--'}; % Estilos para simulación

for i = 1:length(archivos)
    nombre_archivo = archivos{i};
    valor_U = valores_U(i);
    datos_reales = csvread(nombre_archivo, 1, 0);
    t_real = datos_reales(:, 1)/1000; % Convert time to seconds
    Y_real = datos_reales(:, 2);
    lineWidth_real = 1.5;
    lineWidth_sim = 1.5;
    if i == 1 || i == 2
        lineWidth_real = 2;
        lineWidth_sim = 2;
    end
    
    current_style_real = line_styles_real{mod(i - 1, length(line_styles_real)) + 1};
    current_style_sim = line_styles_sim{mod(i - 1, length(line_styles_sim)) + 1};
    
    % Simulate the response of the identified transfer function with this input U
    % Assuming funciones_transferencia{i} is a tf object
    try
        Y_simulado = step(funciones_transferencia{i}, t_real);
        Y_simulado_escalado = Y_simulado * valor_U; % Scale by the input magnitude
        plot(t_real, Y_real, 'k', 'LineWidth', lineWidth_real, 'LineStyle', current_style_real, 'DisplayName', sprintf('Real (U=%g)', valor_U)); % Real data with color and linewidth
        plot(t_real(1:length(Y_simulado_escalado)), Y_simulado_escalado, 'k--', 'LineWidth', lineWidth_sim, 'LineStyle', current_style_sim, 'DisplayName', sprintf('TF (U=%g)', valor_U)); % Simulated response with lighter color, dashed line and linewidth
    catch ME
        warning(['Error simulating transfer function for ', nombre_archivo, ': ', ME.message]);
        % If there's an error in step, try lsim as a fallback (assuming tf object)
        try
            U_step = ones(length(t_real), 1) * valor_U;
            Y_simulado_lsim = lsim(funciones_transferencia{i}, U_step, t_real);
            plot(t_real, Y_real, 'k', 'LineWidth', lineWidth_real, 'LineStyle', current_style_real, 'DisplayName', sprintf('Real (U=%g)', valor_U)); % Real data with color and linewidth
            plot(t_real, Y_simulado_lsim, 'k--', 'LineWidth', lineWidth_sim, 'LineStyle', current_style_sim, 'DisplayName', sprintf('TF (U=%g) (lsim)', valor_U)); % Simulated response with lighter color, dashed line and linewidth
        catch ME_lsim
            warning(['Error using lsim for ', nombre_archivo, ': ', ME_lsim.message]);
            plot(t_real, Y_real, 'k', 'LineWidth', lineWidth_real, 'LineStyle', current_style_real, 'DisplayName', sprintf('Real (U=%g)', valor_U)); % Still plot real data if simulation fails
        end
    end
end
legend('FontSize', 8, 'Location', 'best');
hold off;

legend('Location', 'best');

% --- Evaluate Transfer Functions using Root Mean Squared Error (RMSE) ---
disp(' ');
disp('--- Evaluation of Transfer Functions (RMSE) ---');
rmse_values = zeros(length(funciones_transferencia), length(archivos));
for j = 1:length(funciones_transferencia)
    tf_actual = funciones_transferencia{j};
    disp(['Transfer Function identified from ', archivos{j}, ' (U=', num2str(valores_U(j)), '):']);
    for k = 1:length(archivos)
        nombre_archivo_eval = archivos{k};
        valor_U_eval = valores_U(k);
        datos_eval = csvread(nombre_archivo_eval, 1, 0);
        t_eval = datos_eval(:, 1)/1000;
        Y_real_eval = datos_eval(:, 2);
        try
            Y_simulado_eval = step(tf_actual, t_eval);
            Y_simulado_escalado_eval = Y_simulado_eval * valor_U_eval;
            % Ensure both vectors have the same length for RMSE calculation
            min_length = min(length(Y_real_eval), length(Y_simulado_escalado_eval));
            error = Y_real_eval(1:min_length) - Y_simulado_escalado_eval(1:min_length);
            rmse = sqrt(mean(error.^2));
            rmse_values(j, k) = rmse;
            disp(['  RMSE with ', nombre_archivo_eval, ' (U=', num2str(valor_U_eval), '): ', num2str(rmse)]);
        catch ME_eval_step
            warning(['Error simulating transfer function from ', archivos{j}, ' with input from ', nombre_archivo_eval, ' (step): ', ME_eval_step.message]);
            try
                U_eval_step = ones(length(t_eval), 1) * valor_U_eval;
                Y_simulado_lsim_eval = lsim(tf_actual, U_eval_step, t_eval);
                min_length_lsim = min(length(Y_real_eval), length(Y_simulado_lsim_eval));
                error_lsim = Y_real_eval(1:min_length_lsim) - Y_simulado_lsim_eval(1:min_length_lsim);
                rmse_lsim = sqrt(mean(error_lsim.^2));
                rmse_values(j, k) = rmse_lsim;
                disp(['  RMSE with ', nombre_archivo_eval, ' (U=', num2str(valor_U_eval), ') (using lsim): ', num2str(rmse_lsim)]);
            catch ME_eval_lsim
                warning(['  Error simulating transfer function from ', archivos{j}, ' with input from ', nombre_archivo_eval, ' (lsim): ', ME_eval_lsim.message]);
                rmse_values(j, k) = Inf; % Assign a high value if simulation fails
                disp(['  RMSE with ', nombre_archivo_eval, ' (U=', num2str(valor_U_eval), '): Simulation Failed']);
            end
        end
    end
    disp(' ');
end

% Determine the transfer function with the lowest average RMSE
average_rmse = mean(rmse_values, 2);
[min_avg_rmse, best_tf_index_avg] = min(average_rmse);
best_tf = funciones_transferencia{best_tf_index_avg};

disp('--- Best Transfer Function based on Minimum Average RMSE ---');
if best_tf_index_avg ~= -1
    disp(['The transfer function identified from ', archivos{best_tf_index_avg}, ' (U=', num2str(valores_U(best_tf_index_avg)), ')']);
    disp(['has the lowest average RMSE when compared to all four datasets: ', num2str(min_avg_rmse)]);
    disp('Best Transfer Function (based on average RMSE):');
    disp(best_tf);
else
    disp('Could not determine the best transfer function based on average RMSE due to simulation errors.');
end

% --- Second Figure: Plot the estimated response using the best transfer function for each input U ---
figure;
hold on;
xlabel('Time [s]');
ylabel('Shaft speed [RPM]');
grid on;
grid minor; % Añadir líneas de cuadrícula menores para mejor legibilidad en B/N
ax = gca;
ax.FontSize = 10;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
line_styles_real_fig2 = {'-', '--', ':', '-.'}; % Estilos para datos reales
line_styles_sim_fig2 = {':', '-.', '-', '--'}; % Estilos para simulación

for i = 1:length(archivos)
    nombre_archivo = archivos{i};
    valor_U = valores_U(i);
    datos_reales = csvread(nombre_archivo, 1, 0);
    t_real = datos_reales(:, 1)/1000;
    Y_real = datos_reales(:, 2);
    
    current_style_real_fig2 = line_styles_real_fig2{mod(i - 1, length(line_styles_real_fig2)) + 1};
    current_style_sim_fig2 = line_styles_sim_fig2{mod(i - 1, length(line_styles_sim_fig2)) + 1};
    
    try
        Y_simulado_best_tf = step(best_tf, t_real);
        Y_simulado_escalado_best_tf = Y_simulado_best_tf * valor_U;
        plot(t_real, Y_real, 'k', 'LineStyle', current_style_real_fig2, 'DisplayName', sprintf('Real (U=%g)', valor_U));
        plot(t_real(1:length(Y_simulado_escalado_best_tf)), Y_simulado_escalado_best_tf, 'k--', 'LineStyle', current_style_sim_fig2, 'DisplayName', sprintf('Estimated (U=%g)', valor_U));
    catch ME
        warning(['Error simulating best transfer function for ', nombre_archivo, ': ', ME.message]);
        try
            U_step_best = ones(length(t_real), 1) * valor_U;
            Y_simulado_lsim_best_tf = lsim(best_tf, U_step_best, t_real);
            plot(t_real, Y_real, 'k', 'LineStyle', current_style_real_fig2, 'DisplayName', sprintf('Real (U=%g)', valor_U));
            plot(t_real, Y_simulado_lsim_best_tf, 'k--', 'LineStyle', current_style_sim_fig2, 'DisplayName', sprintf('Estimated (U=%g) (lsim)', valor_U));
        catch ME_lsim_best
            warning(['Error using lsim with best transfer function for ', nombre_archivo, ': ', ME_lsim_best.message]);
            plot(t_real, Y_real, 'k', 'LineStyle', current_style_real_fig2, 'DisplayName', sprintf('Real (U=%g)', valor_U));
        end
    end
end
legend('FontSize', 8, 'Location', 'best');
hold off;

hold off;
legend('Location', 'best');