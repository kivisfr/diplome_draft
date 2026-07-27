function depression()
clear; clc; close all;
% ======================================================================
% ИНИЦИАЛИЗАЦИЯ ДАННЫХ
% ======================================================================
app_data = struct();
app_data.lambda0 = 800;  % в нм
app_data.w0 = 20;          % в мкм
app_data.N_layers = 4;
app_data.fig_handles = [];
app_data.adv_status = [];
app_data.layer_windows = cell(10, 1);
app_data.n_angle_points = 5000;  % === НОВОЕ: количество точек по углу ===

% УНИФИЦИРОВАННАЯ СТРУКТУРА СЛОЯ (14 элементов для всех)
default_layers = {
% 1
{4, 0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 0, Inf, 'constant'},
% 2
{9.84, 1.37e16, 1.2e14, 0, 0, 0, 1.0, 0, 0, 0, 0, 0, 50e-9, 'drude'},
% 3
{1.0, 0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 0, 50e-9, 'constant'},
% 4
{1.0, 0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 0, 50e-9, 'constant'}
};
app_data.layers = cell(10, 1);
for i = 1:10
    if i <= length(default_layers)
        app_data.layers{i} = default_layers{i};
    else
        app_data.layers{i} = {1.0, 0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 0, 100e-9, 'constant'};
    end
end

% ======================================================================
% СОЗДАНИЕ ГЛАВНОГО ОКНА
% ======================================================================
h_main = figure('Name', 'GH/IF Сдвиги - Интерактивный Расчет', ...
    'Position', [100, 100, 550, 800], ...
    'MenuBar', 'none', 'ToolBar', 'none', ...
    'NumberTitle', 'off', 'Resize', 'off', ...
    'Color', [0.95, 0.95, 0.95]);
app_data.main_fig = h_main;

% Заголовок
uicontrol('Parent', h_main, 'Style', 'text', ...
    'String', 'ИНТЕРАКТИВНЫЙ РАСЧЕТ СДВИГОВ ГУСА-ХЕНХЕН И ИМБЕРТА-ФЕДОРОВА', ...
    'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
    'Position', [20, 750, 510, 40], 'BackgroundColor', [0.95, 0.95, 0.95]);
uipanel('Parent', h_main, 'Position', [20, 730, 510, 2], ...
    'BackgroundColor', [0.3, 0.3, 0.3], 'BorderType', 'none');

% ======================================================================
% ПАРАМЕТРЫ ИЗЛУЧЕНИЯ
% ======================================================================
uicontrol('Parent', h_main, 'Style', 'text', ...
    'String', 'ПАРАМЕТРЫ ИЗЛУЧЕНИЯ', ...
    'FontSize', 11, 'FontWeight', 'bold', ...
    'Position', [20, 690, 510, 25]);
uicontrol('Parent', h_main, 'Style', 'text', ...
    'String', 'Длина волны λ₀:', ...
    'Position', [20, 660, 100, 25]);
app_data.lambda_edit = uicontrol('Parent', h_main, ...
    'Style', 'edit', 'String', '632.8', ...
    'Position', [130, 660, 70, 25], 'FontSize', 10);
uicontrol('Parent', h_main, 'Style', 'text', ...
    'String', 'нм', ...
    'Position', [210, 660, 30, 25], 'FontSize', 10);
uicontrol('Parent', h_main, 'Style', 'text', ...
    'String', 'Перетяжка w₀:', ...
    'Position', [260, 660, 90, 25]);
app_data.w0_edit = uicontrol('Parent', h_main, ...
    'Style', 'edit', 'String', '20', ...
    'Position', [360, 660, 60, 25], 'FontSize', 10);
uicontrol('Parent', h_main, 'Style', 'text', ...
    'String', 'мкм', ...
    'Position', [430, 660, 40, 25], 'FontSize', 10);
uipanel('Parent', h_main, 'Position', [20, 640, 510, 2], ...
    'BackgroundColor', [0.3, 0.3, 0.3], 'BorderType', 'none');

% ======================================================================
% СТРУКТУРА СЛОЕВ
% ======================================================================
uicontrol('Parent', h_main, 'Style', 'text', ...
    'String', 'СТРУКТУРА СЛОЕВ', ...
    'FontSize', 11, 'FontWeight', 'bold', ...
    'Position', [20, 600, 510, 25]);
uicontrol('Parent', h_main, 'Style', 'text', ...
    'String', 'Количество слоев:', ...
    'Position', [20, 570, 120, 25]);
app_data.n_layers_slider = uicontrol('Parent', h_main, ...
    'Style', 'slider', 'Min', 1, 'Max', 10, 'Value', 4, ...
    'Position', [150, 570, 220, 25], ...
    'Callback', @update_n_layers_callback);
app_data.n_layers_text = uicontrol('Parent', h_main, ...
    'Style', 'text', 'String', '4', ...
    'Position', [380, 570, 40, 25], ...
    'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

% Кнопки для настройки каждого слоя
app_data.layer_buttons = cell(10, 1);
for i = 1:10
    app_data.layer_buttons{i} = uicontrol('Parent', h_main, ...
        'Style', 'pushbutton', ...
        'String', sprintf('Слой %d: Настроить', i), ...
        'Position', [20, 545-(i-1)*32, 510, 27], ...
        'FontSize', 9, ...
        'Visible', 'off', ...
        'Callback', {@open_layer_window_callback, i});
end
uipanel('Parent', h_main, 'Position', [20, 215, 510, 2], ...
    'BackgroundColor', [0.3, 0.3, 0.3], 'BorderType', 'none');

% ======================================================================
% ВЫБОР ТИПОВ ГРАФИКОВ
% ======================================================================
uicontrol('Parent', h_main, 'Style', 'text', ...
    'String', 'ОТОБРАЖАЕМЫЕ ГРАФИКИ', ...
    'FontSize', 11, 'FontWeight', 'bold', ...
    'Position', [20, 180, 510, 25]);
app_data.fig1_check = uicontrol('Parent', h_main, ...
    'Style', 'checkbox', 'String', 'Пространственные GH', ...
    'Position', [20, 155, 140, 25], 'Value', 1, 'FontSize', 10);
app_data.fig2_check = uicontrol('Parent', h_main, ...
    'Style', 'checkbox', 'String', 'Пространственные IF', ...
    'Position', [170, 155, 140, 25], 'Value', 1, 'FontSize', 10);
app_data.fig3_check = uicontrol('Parent', h_main, ...
    'Style', 'checkbox', 'String', 'Угловые GH', ...
    'Position', [320, 155, 140, 25], 'Value', 1, 'FontSize', 10);
app_data.fig4_check = uicontrol('Parent', h_main, ...
    'Style', 'checkbox', 'String', 'Угловые IF', ...
    'Position', [20, 130, 140, 25], 'Value', 1, 'FontSize', 10);

% ======================================================================
% КНОПКИ РАСЧЁТА
% ======================================================================
app_data.calc_button = uicontrol('Parent', h_main, ...
    'Style', 'pushbutton', ...
    'String', '▶ СТАНДАРТНЫЕ ГРАФИКИ', ...
    'Position', [20, 80, 510, 45], ...
    'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.2, 0.6, 0.2], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', @start_calculation_callback);

% НОВАЯ КНОПКА: Продвинутые графики
app_data.advanced_button = uicontrol('Parent', h_main, ...
    'Style', 'pushbutton', ...
    'String', '📊 ПРОДВИНУТЫЕ ГРАФИКИ', ...
    'Position', [20, 30, 510, 45], ...
    'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.2, 0.4, 0.8], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', @start_advanced_calculation_callback);

% Статус
app_data.status_text = uicontrol('Parent', h_main, ...
    'Style', 'text', 'String', 'Готов к расчету', ...
    'Position', [20, 10, 510, 15], ...
    'FontSize', 9, 'HorizontalAlignment', 'center', ...
    'ForegroundColor', [0, 0.5, 0]);

assignin('base', 'gh_if_app_data', app_data);
update_layer_buttons_visibility(app_data);
end

% ======================================================================
% CALLBACK: Обновление количества слоев
% ======================================================================
function update_n_layers_callback(src, ~)
    app_data = get_app_data();
    n = round(get(src, 'Value'));
    set(app_data.n_layers_text, 'String', num2str(n));
    app_data.N_layers = n;
    update_layer_buttons_visibility(app_data);
    h_adv = findall(0, 'Name', 'Продвинутые графики - Настройка');
    if ~isempty(h_adv)
        update_layer_lists(h_adv(1), n);
    end
    assignin('base', 'gh_if_app_data', app_data);
end

% ======================================================================
% ОБНОВЛЕНИЕ ВИДИМОСТИ КНОПОК СЛОЕВ
% ======================================================================
function update_layer_buttons_visibility(app_data)
    for i = 1:10
        if i <= app_data.N_layers
            set(app_data.layer_buttons{i}, 'Visible', 'on');
            layer_data = app_data.layers{i};
            if isinf(layer_data{13})
                thick_str = '∞';
            else
                thick_str = sprintf('%.0f нм', layer_data{13}*1e9);
            end
            if strcmp(layer_data{14}, 'constant')
                eps_str = sprintf('%.2f%+.2fi', layer_data{1}, layer_data{2});
                mu_str = sprintf('%.2f%+.2fi', layer_data{7}, layer_data{8});
            else
                eps_str = sprintf('%.2f (дисп.)', layer_data{1});
                mu_str = sprintf('%.2f (дисп.)', layer_data{7});
            end
            set(app_data.layer_buttons{i}, 'String', ...
                sprintf('Слой %d: %s | ε=%s | μ=%s', i, thick_str, eps_str, mu_str));
        else
            set(app_data.layer_buttons{i}, 'Visible', 'off');
        end
    end
end

% ======================================================================
% CALLBACK: Открытие окна настройки слоя
% ======================================================================
function open_layer_window_callback(~, ~, layer_num)
    app_data = get_app_data();
    create_layer_window(app_data, layer_num);
end

% ======================================================================
% СОЗДАНИЕ ОКНА НАСТРОЙКИ СЛОЯ
% ======================================================================
function create_layer_window(app_data, layer_num)
    if ishandle(app_data.layer_windows{layer_num})
        close(app_data.layer_windows{layer_num});
    end
    h_layer = figure('Name', sprintf('Настройка Слой %d', layer_num), ...
        'Position', [750, 150, 600, 750], ...
        'MenuBar', 'none', 'ToolBar', 'none', ...
        'NumberTitle', 'off', 'Resize', 'off', ...
        'Color', [0.95, 0.95, 0.95]);
    layer_data = app_data.layers{layer_num};
    
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', sprintf('ПАРАМЕТРЫ СЛОЯ %d', layer_num), ...
        'FontSize', 13, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
        'Position', [20, 700, 560, 35]);
    
    % ТОЛЩИНА СЛОЯ
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'ТОЛЩИНА СЛОЯ', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'Position', [20, 655, 560, 25]);
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'Толщина d:', ...
        'Position', [20, 625, 80, 25]);
    if isinf(layer_data{13})
        thick_val = 'Inf';
    else
        thick_val = sprintf('%.1f', layer_data{13}*1e9);
    end
    h_thick = uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', thick_val, ...
        'Position', [110, 625, 80, 25], 'FontSize', 10, ...
        'Tag', 'thickness');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'нм', 'Position', [200, 625, 30, 25]);
    uicontrol('Parent', h_layer, 'Style', 'checkbox', ...
        'String', 'Полубесконечный', ...
        'Position', [250, 625, 150, 25], ...
        'Value', isinf(layer_data{13}), ...
        'Tag', 'infinite_check', ...
        'Callback', @toggle_infinite_callback);
    
    % ТИП МАТЕРИАЛА
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'ТИП МАТЕРИАЛА', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'Position', [20, 585, 560, 25]);
    h_material_type = uicontrol('Parent', h_layer, ...
        'Style', 'popupmenu', ...
        'String', 'Постоянный (без дисперсии)|Друде-Лоренц (дисперсия)', ...
        'Position', [20, 555, 560, 25], ...
        'FontSize', 10, ...
        'Tag', 'material_type', ...
        'Callback', @toggle_material_type_callback);
    if strcmp(layer_data{14}, 'constant')
        set(h_material_type, 'Value', 1);
    else
        set(h_material_type, 'Value', 2);
    end
    
    % ПАРАМЕТРЫ - ПОСТОЯННЫЙ МАТЕРИАЛ
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'ПАРАМЕТРЫ (Постоянный материал)', ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'Position', [20, 520, 560, 20], ...
        'Tag', 'constant_header');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'Re(ε):', 'Position', [20, 495, 50, 25], ...
        'Tag', 'constant_eps_re_label');
    h_eps_re = uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2f', layer_data{1}), ...
        'Position', [80, 495, 70, 25], 'FontSize', 10, ...
        'Tag', 'eps_re');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'Im(ε):', 'Position', [170, 495, 50, 25], ...
        'Tag', 'constant_eps_im_label');
    h_eps_im = uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2f', layer_data{2}), ...
        'Position', [230, 495, 70, 25], 'FontSize', 10, ...
        'Tag', 'eps_im');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'Re(μ):', 'Position', [320, 495, 50, 25], ...
        'Tag', 'constant_mu_re_label');
    h_mu_re = uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2f', layer_data{7}), ...
        'Position', [380, 495, 70, 25], 'FontSize', 10, ...
        'Tag', 'mu_re');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'Im(μ):', 'Position', [470, 495, 50, 25], ...
        'Tag', 'constant_mu_im_label');
    h_mu_im = uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2f', layer_data{8}), ...
        'Position', [530, 495, 70, 25], 'FontSize', 10, ...
        'Tag', 'mu_im');
    
    % ПАРАМЕТРЫ - ДИСПЕРСИОННЫЙ МАТЕРИАЛ
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'ПАРАМЕТРЫ (Модель Друде-Лоренца)', ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'Position', [20, 460, 560, 20], ...
        'Tag', 'dispersion_header', 'Visible', 'off');
    
    % Электрическая проницаемость
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'Электрическая проницаемость ε(ω):', ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'Position', [20, 430, 280, 20], ...
        'Tag', 'dispersion_eps_header', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'ε∞:', 'Position', [20, 405, 30, 20], ...
        'Tag', 'dispersion_eps_inf_label', 'Visible', 'off');
    uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2f', layer_data{1}), ...
        'Position', [55, 405, 60, 20], 'FontSize', 9, ...
        'Tag', 'eps_inf', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'ωₚ (Друде):', 'Position', [130, 405, 80, 20], ...
        'Tag', 'dispersion_eps_wp_label', 'Visible', 'off');
    uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2e', layer_data{2}), ...
        'Position', [215, 405, 90, 20], 'FontSize', 9, ...
        'Tag', 'eps_wp', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'рад/с', 'Position', [310, 405, 40, 20], 'FontSize', 8, ...
        'Tag', 'dispersion_eps_wp_unit', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'γ:', 'Position', [360, 405, 20, 20], ...
        'Tag', 'dispersion_eps_gamma_label', 'Visible', 'off');
    uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2e', layer_data{3}), ...
        'Position', [385, 405, 70, 20], 'FontSize', 9, ...
        'Tag', 'eps_gamma', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'рад/с', 'Position', [460, 405, 40, 20], 'FontSize', 8, ...
        'Tag', 'dispersion_eps_gamma_unit', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'f (Лоренц):', 'Position', [20, 380, 70, 20], ...
        'Tag', 'dispersion_eps_f_label', 'Visible', 'off');
    uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2f', layer_data{4}), ...
        'Position', [95, 380, 70, 20], 'FontSize', 9, ...
        'Tag', 'eps_f', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'безр.', 'Position', [170, 380, 40, 20], 'FontSize', 8, ...
        'Tag', 'dispersion_eps_f_unit', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'ω₀:', 'Position', [220, 380, 30, 20], ...
        'Tag', 'dispersion_eps_w0_label', 'Visible', 'off');
    uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2e', layer_data{5}), ...
        'Position', [255, 380, 80, 20], 'FontSize', 9, ...
        'Tag', 'eps_w0', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'рад/с', 'Position', [340, 380, 40, 20], 'FontSize', 8, ...
        'Tag', 'dispersion_eps_w0_unit', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'Γ:', 'Position', [390, 380, 20, 20], ...
        'Tag', 'dispersion_eps_Gamma_label', 'Visible', 'off');
    uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2e', layer_data{6}), ...
        'Position', [415, 380, 70, 20], 'FontSize', 9, ...
        'Tag', 'eps_Gamma', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'рад/с', 'Position', [490, 380, 40, 20], 'FontSize', 8, ...
        'Tag', 'dispersion_eps_Gamma_unit', 'Visible', 'off');
    
    % Магнитная проницаемость
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'Магнитная проницаемость μ(ω):', ...
        'FontSize', 9, 'FontWeight', 'bold', ...
        'Position', [20, 350, 280, 20], ...
        'Tag', 'dispersion_mu_header', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'μ∞:', 'Position', [20, 325, 30, 20], ...
        'Tag', 'dispersion_mu_inf_label', 'Visible', 'off');
    uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2f', layer_data{7}), ...
        'Position', [55, 325, 60, 20], 'FontSize', 9, ...
        'Tag', 'mu_inf', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'ωₚ (Друде):', 'Position', [130, 325, 80, 20], ...
        'Tag', 'dispersion_mu_wp_label', 'Visible', 'off');
    uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2e', layer_data{8}), ...
        'Position', [215, 325, 90, 20], 'FontSize', 9, ...
        'Tag', 'mu_wp', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'рад/с', 'Position', [310, 325, 40, 20], 'FontSize', 8, ...
        'Tag', 'dispersion_mu_wp_unit', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'γ:', 'Position', [360, 325, 20, 20], ...
        'Tag', 'dispersion_mu_gamma_label', 'Visible', 'off');
    uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2e', layer_data{9}), ...
        'Position', [385, 325, 70, 20], 'FontSize', 9, ...
        'Tag', 'mu_gamma', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'рад/с', 'Position', [460, 325, 40, 20], 'FontSize', 8, ...
        'Tag', 'dispersion_mu_gamma_unit', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'f (Лоренц):', 'Position', [20, 300, 70, 20], ...
        'Tag', 'dispersion_mu_f_label', 'Visible', 'off');
    uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2f', layer_data{10}), ...
        'Position', [95, 300, 70, 20], 'FontSize', 9, ...
        'Tag', 'mu_f', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'безр.', 'Position', [170, 300, 40, 20], 'FontSize', 8, ...
        'Tag', 'dispersion_mu_f_unit', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'ω₀:', 'Position', [220, 300, 30, 20], ...
        'Tag', 'dispersion_mu_w0_label', 'Visible', 'off');
    uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2e', layer_data{11}), ...
        'Position', [255, 300, 80, 20], 'FontSize', 9, ...
        'Tag', 'mu_w0', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'рад/с', 'Position', [340, 300, 40, 20], 'FontSize', 8, ...
        'Tag', 'dispersion_mu_w0_unit', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'Γ:', 'Position', [390, 300, 20, 20], ...
        'Tag', 'dispersion_mu_Gamma_label', 'Visible', 'off');
    uicontrol('Parent', h_layer, ...
        'Style', 'edit', 'String', sprintf('%.2e', layer_data{12}), ...
        'Position', [415, 300, 70, 20], 'FontSize', 9, ...
        'Tag', 'mu_Gamma', 'Visible', 'off');
    uicontrol('Parent', h_layer, 'Style', 'text', ...
        'String', 'рад/с', 'Position', [490, 300, 40, 20], 'FontSize', 8, ...
        'Tag', 'dispersion_mu_Gamma_unit', 'Visible', 'off');
    
    % КНОПКИ
    uicontrol('Parent', h_layer, 'Style', 'pushbutton', ...
        'String', 'ПРИМЕНИТЬ И ЗАКРЫТЬ', ...
        'Position', [175, 240, 250, 35], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2, 0.6, 0.2], ...
        'ForegroundColor', [1, 1, 1], ...
        'Callback', {@apply_layer_callback, layer_num});
    uicontrol('Parent', h_layer, 'Style', 'pushbutton', ...
        'String', 'ОТМЕНА', ...
        'Position', [175, 200, 250, 30], ...
        'FontSize', 10, ...
        'Callback', {@cancel_layer_callback, layer_num});
    
    app_data.layer_windows{layer_num} = h_layer;
    assignin('base', 'gh_if_app_data', app_data);
    toggle_material_type_callback(h_material_type, [], layer_num);
end

% ======================================================================
% CALLBACK: Переключение полубесконечный/нет
% ======================================================================
function toggle_infinite_callback(src, ~)
    h_layer = gcbf;
    val = get(src, 'Value');
    h_thick = findobj(h_layer, 'Tag', 'thickness');
    if val
        set(h_thick, 'String', 'Inf', 'Enable', 'off');
    else
        set(h_thick, 'Enable', 'on');
    end
end

% ======================================================================
% CALLBACK: Переключение типа материала
% ======================================================================
function toggle_material_type_callback(src, ~, ~)
    h_layer = gcbf;
    val = get(src, 'Value');
    if val == 1
        constant_vis = 'on';
        dispersion_vis = 'off';
    else
        constant_vis = 'off';
        dispersion_vis = 'on';
    end
    
    set(findobj(h_layer, 'Tag', 'constant_header'), 'Visible', constant_vis);
    set(findobj(h_layer, 'Tag', 'constant_eps_re_label'), 'Visible', constant_vis);
    set(findobj(h_layer, 'Tag', 'eps_re'), 'Visible', constant_vis);
    set(findobj(h_layer, 'Tag', 'constant_eps_im_label'), 'Visible', constant_vis);
    set(findobj(h_layer, 'Tag', 'eps_im'), 'Visible', constant_vis);
    set(findobj(h_layer, 'Tag', 'constant_mu_re_label'), 'Visible', constant_vis);
    set(findobj(h_layer, 'Tag', 'mu_re'), 'Visible', constant_vis);
    set(findobj(h_layer, 'Tag', 'constant_mu_im_label'), 'Visible', constant_vis);
    set(findobj(h_layer, 'Tag', 'mu_im'), 'Visible', constant_vis);
    
    set(findobj(h_layer, 'Tag', 'dispersion_header'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_eps_header'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_eps_inf_label'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'eps_inf'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_eps_wp_label'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'eps_wp'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_eps_wp_unit'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_eps_gamma_label'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'eps_gamma'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_eps_gamma_unit'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_eps_f_label'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'eps_f'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_eps_f_unit'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_eps_w0_label'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'eps_w0'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_eps_w0_unit'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_eps_Gamma_label'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'eps_Gamma'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_eps_Gamma_unit'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_mu_header'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_mu_inf_label'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'mu_inf'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_mu_wp_label'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'mu_wp'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_mu_wp_unit'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_mu_gamma_label'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'mu_gamma'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_mu_gamma_unit'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_mu_f_label'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'mu_f'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_mu_f_unit'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_mu_w0_label'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'mu_w0'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_mu_w0_unit'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_mu_Gamma_label'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'mu_Gamma'), 'Visible', dispersion_vis);
    set(findobj(h_layer, 'Tag', 'dispersion_mu_Gamma_unit'), 'Visible', dispersion_vis);
end

% ======================================================================
% CALLBACK: Применить настройки слоя
% ======================================================================
function apply_layer_callback(~, ~, layer_num)
    app_data = get_app_data();
    h_layer = gcbf;
    h_thick = findobj(h_layer, 'Tag', 'thickness');
    h_infinite = findobj(h_layer, 'Tag', 'infinite_check');
    if get(h_infinite, 'Value')
        thickness = Inf;
    else
        thickness = str2double(get(h_thick, 'String')) * 1e-9;
    end
    h_material = findobj(h_layer, 'Tag', 'material_type');
    material_type = get(h_material, 'Value');
    new_layer_data = cell(1, 14);
    new_layer_data{13} = thickness;
    if material_type == 1
        new_layer_data{1} = str2double(get(findobj(h_layer, 'Tag', 'eps_re'), 'String'));
        new_layer_data{2} = str2double(get(findobj(h_layer, 'Tag', 'eps_im'), 'String'));
        new_layer_data{3} = 0; new_layer_data{4} = 0; new_layer_data{5} = 0; new_layer_data{6} = 0;
        new_layer_data{7} = str2double(get(findobj(h_layer, 'Tag', 'mu_re'), 'String'));
        new_layer_data{8} = str2double(get(findobj(h_layer, 'Tag', 'mu_im'), 'String'));
        new_layer_data{9} = 0; new_layer_data{10} = 0; new_layer_data{11} = 0; new_layer_data{12} = 0;
        new_layer_data{14} = 'constant';
    else
        new_layer_data{1} = str2double(get(findobj(h_layer, 'Tag', 'eps_inf'), 'String'));
        new_layer_data{2} = str2double(get(findobj(h_layer, 'Tag', 'eps_wp'), 'String'));
        new_layer_data{3} = str2double(get(findobj(h_layer, 'Tag', 'eps_gamma'), 'String'));
        new_layer_data{4} = str2double(get(findobj(h_layer, 'Tag', 'eps_f'), 'String'));
        new_layer_data{5} = str2double(get(findobj(h_layer, 'Tag', 'eps_w0'), 'String'));
        new_layer_data{6} = str2double(get(findobj(h_layer, 'Tag', 'eps_Gamma'), 'String'));
        new_layer_data{7} = str2double(get(findobj(h_layer, 'Tag', 'mu_inf'), 'String'));
        new_layer_data{8} = str2double(get(findobj(h_layer, 'Tag', 'mu_wp'), 'String'));
        new_layer_data{9} = str2double(get(findobj(h_layer, 'Tag', 'mu_gamma'), 'String'));
        new_layer_data{10} = str2double(get(findobj(h_layer, 'Tag', 'mu_f'), 'String'));
        new_layer_data{11} = str2double(get(findobj(h_layer, 'Tag', 'mu_w0'), 'String'));
        new_layer_data{12} = str2double(get(findobj(h_layer, 'Tag', 'mu_Gamma'), 'String'));
        new_layer_data{14} = 'drude_lorentz';
    end
    app_data.layers{layer_num} = new_layer_data;
    close(h_layer);
    app_data.layer_windows{layer_num} = [];
    if isinf(thickness)
        thick_str = '∞';
    else
        thick_str = sprintf('%.0f нм', thickness*1e9);
    end
    if material_type == 1
        eps_str = sprintf('%.2f%+.2fi', new_layer_data{1}, new_layer_data{2});
        mu_str = sprintf('%.2f%+.2fi', new_layer_data{7}, new_layer_data{8});
    else
        eps_str = 'Дисп.';
        mu_str = 'Дисп.';
    end
    set(app_data.layer_buttons{layer_num}, 'String', ...
        sprintf('Слой %d: %s | ε=%s | μ=%s', layer_num, thick_str, eps_str, mu_str));
    assignin('base', 'gh_if_app_data', app_data);
end

% ======================================================================
% CALLBACK: Отмена настроек слоя
% ======================================================================
function cancel_layer_callback(~, ~, layer_num)
    h_layer = gcbf;
    close(h_layer);
    app_data = get_app_data();
    app_data.layer_windows{layer_num} = [];
    assignin('base', 'gh_if_app_data', app_data);
end

% ======================================================================
% CALLBACK: СТАНДАРТНЫЕ ГРАФИКИ (ИЗМЕНЁННАЯ ВЕРСИЯ)
% ======================================================================
function start_calculation_callback(~, ~)
    app_data = get_app_data();
    set(app_data.status_text, 'String', 'Выполняется расчет...', ...
        'ForegroundColor', [1, 0.5, 0]);
    drawnow;
    
    try
        % === ИНИЦИАЛИЗАЦИЯ ПАРАЛЛЕЛЬНОГО ПУЛА ===
        init_parallel_pool();
        use_parfor = check_parfor_available();
        
        lambda0 = str2double(get(app_data.lambda_edit, 'String')) * 1e-9;
        w0 = str2double(get(app_data.w0_edit, 'String')) * 1e-6;
        N_layers = app_data.N_layers;
        show_fig1 = get(app_data.fig1_check, 'Value');
        show_fig2 = get(app_data.fig2_check, 'Value');
        show_fig3 = get(app_data.fig3_check, 'Value');
        show_fig4 = get(app_data.fig4_check, 'Value');
        
        if ~(show_fig1 || show_fig2 || show_fig3 || show_fig4)
            warndlg('Выберите хотя бы один тип графиков!', 'Ошибка');
            set(app_data.status_text, 'String', 'Ошибка: не выбраны графики', ...
                'ForegroundColor', [1, 0, 0]);
            return;
        end
        
        layers = struct();
        for i = 1:N_layers
            layer_data = app_data.layers{i};
            layers(i).eps_inf = layer_data{1};
            layers(i).eps_drude.omega_p = layer_data{2};
            layers(i).eps_drude.gamma = layer_data{3};
            if layer_data{4} > 0
                layers(i).eps_lorentz = struct('f', layer_data{4}, ...
                    'omega_0', layer_data{5}, 'Gamma', layer_data{6});
            else
                layers(i).eps_lorentz = [];
            end
            layers(i).mu_inf = layer_data{7};
            layers(i).mu_drude.omega_p = layer_data{8};
            layers(i).mu_drude.gamma = layer_data{9};
            if layer_data{10} > 0
                layers(i).mu_lorentz = struct('f', layer_data{10}, ...
                    'omega_0', layer_data{11}, 'Gamma', layer_data{12});
            else
                layers(i).mu_lorentz = [];
            end
            layers(i).d = layer_data{13};
        end
        
        % === СТАНДАРТНЫЕ ГРАФИКИ ===
        calculate_and_plot(lambda0, w0, N_layers, layers, show_fig1, show_fig2, show_fig3, show_fig4);
        
        if use_parfor
            set(app_data.status_text, 'String', 'Расчет успешно завершен (параллельный)!', ...
                'ForegroundColor', [0, 0.5, 0]);
        else
            set(app_data.status_text, 'String', 'Расчет успешно завершен!', ...
                'ForegroundColor', [0, 0.5, 0]);
        end
    catch ME
        warndlg(sprintf('Ошибка расчета: %s', ME.message), 'Ошибка');
        set(app_data.status_text, 'String', 'Ошибка расчета!', ...
            'ForegroundColor', [1, 0, 0]);
    end
end

% ======================================================================
% === ОБНОВЛЁННАЯ ФУНКЦИЯ: РАСЧЁТ И ПОСТРОЕНИЕ ГРАФИКОВ СДВИГОВ ===
% === Версия 2.0: С корректным взвешиванием по интенсивности ===
% ======================================================================
function calculate_and_plot(lambda0, w0, N_layers, layers, show_fig1, show_fig2, show_fig3, show_fig4)
    % Обработка флагов отображения
    if nargin < 5, show_fig1 = true; show_fig2 = true; show_fig3 = true; show_fig4 = true; end
    if nargin < 6, show_fig2 = true; end
    if nargin < 7, show_fig3 = true; end
    if nargin < 8, show_fig4 = true; end
    
    try
        freq0 = 299792458 / lambda0;
        omega0 = 2 * pi * freq0;
        k0 = 2 * pi / lambda0;
        
        % ==================================================================
        % 1. ДИСПЕРСИЯ МАТЕРИАЛОВ
        % ==================================================================
        for i = 1:N_layers
            [eps_i, mu_i] = drude_lorentz_model(omega0, layers(i));
            layers(i).epsilon = eps_i;
            layers(i).mu = mu_i;
        end
        
        % ==================================================================
        % 2. СЕТКА УГЛОВ (фиксированное разрешение для гладких графиков)
        % ==================================================================
        n_angle_points = 5000;
        theta_deg = linspace(0.01, 89.99, n_angle_points);
        theta = deg2rad(theta_deg);
        dtheta = theta(2) - theta(1);
        
        % ==================================================================
        % 3. ВОЛНОВЫЕ ВЕКТОРЫ
        % ==================================================================
        kz = zeros(N_layers, length(theta));
        n = zeros(N_layers, 1);
        for i = 1:N_layers
            n(i) = sqrt(layers(i).epsilon * layers(i).mu);
            kx = k0 * n(1) * sin(theta);
            kz_sq = (k0^2 * layers(i).epsilon * layers(i).mu) - kx.^2;
            kz(i, :) = sqrt(kz_sq);
            % Выбор знака корня: затухание вглубь среды
            kz(i, imag(kz(i,:)) < 0) = -kz(i, imag(kz(i,:)) < 0);
        end
        
        % ==================================================================
        % 4. TMM: КОЭФФИЦИЕНТЫ ОТРАЖЕНИЯ ДЛЯ S И P
        % ==================================================================
        R_total_s = zeros(1, length(theta));
        R_total_p = zeros(1, length(theta));
        
        for idx = 1:length(theta)
            % S-поляризация
            Y_s = kz(:,idx) ./ [layers.mu]';
            M_s = eye(2);
            for i = 1:N_layers-1
                gamma_s = Y_s(i) / Y_s(i+1);
                D_s = 0.5 * [1 + gamma_s, 1 - gamma_s; 1 - gamma_s, 1 + gamma_s];
                if isfinite(layers(i+1).d)
                    phi = kz(i+1,idx) * layers(i+1).d;
                    P_s = [exp(-1i*phi), 0; 0, exp(1i*phi)];
                    M_s = M_s * D_s * P_s;
                else
                    M_s = M_s * D_s;
                end
            end
            R_total_s(idx) = M_s(2,1) / M_s(1,1);
            
            % P-поляризация
            Y_p = kz(:,idx) ./ [layers.epsilon]';
            M_p = eye(2);
            for i = 1:N_layers-1
                gamma_p = Y_p(i) / Y_p(i+1);
                D_p = 0.5 * [1 + gamma_p, 1 - gamma_p; 1 - gamma_p, 1 + gamma_p];
                if isfinite(layers(i+1).d)
                    phi = kz(i+1,idx) * layers(i+1).d;
                    P_p = [exp(-1i*phi), 0; 0, exp(1i*phi)];
                    M_p = M_p * D_p * P_p;
                else
                    M_p = M_p * D_p;
                end
            end
            R_total_p(idx) = M_p(2,1) / M_p(1,1);
        end
        
        % ==================================================================
        % 5. ИНТЕНСИВНОСТИ И ВЕСА
        % ==================================================================
        Int_s = abs(R_total_s).^2;
        Int_p = abs(R_total_p).^2;
        Total_Int = Int_s + Int_p;
        
        % Нормированные веса для взвешенного усреднения
        W_s = Int_s ./ (Total_Int + eps);
        W_p = Int_p ./ (Total_Int + eps);
        
        % Параметр Стокса S3: степень циркулярности отражённого пучка
        % Важен для корректного расчёта сдвига Имберта-Федорова
        S3 = (Int_p - Int_s) ./ (Total_Int + eps);
        
        % ==================================================================
        % 6. ФАЗЫ И ИХ ГРАДИЕНТЫ (для S и P — собственных мод)
        % ==================================================================
        Phi_s = unwrap(angle(R_total_s));
        Phi_p = unwrap(angle(R_total_p));
        
        dPhi_s = gradient(Phi_s, dtheta);
        dPhi_p = gradient(Phi_p, dtheta);
        dDelta_Phi = gradient(Phi_p - Phi_s, dtheta);  % для IF сдвига
        
        % Градиенты логарифмов амплитуд (для угловых сдвигов)
        Amp_s = abs(R_total_s);
        Amp_p = abs(R_total_p);
        dlnAmp_s = gradient(log(Amp_s + eps), dtheta);
        dlnAmp_p = gradient(log(Amp_p + eps), dtheta);
        dAmp_diff = gradient(Amp_p - Amp_s, dtheta);
        
        % ==================================================================
        % 7. МНОЖИТЕЛИ
        % ==================================================================
        n1 = n(1);
        cos_theta = cos(theta);
        sin_theta = sin(theta);
        
        cos_theta_safe = cos_theta;
        cos_theta_safe(abs(cos_theta_safe) < 1e-6) = 1e-6;
        sin_theta_safe = sin_theta;
        sin_theta_safe(abs(sin_theta_safe) < 1e-10) = 1e-10;
        
        % Пространственный множитель
        factor_spatial = -1 ./ (k0 * n1 * cos_theta_safe);
        % Угловой множитель
        factor_angular = 1 ./ (k0^2 * n1^2 * w0^2 * cos_theta_safe);
        
        cot_theta = cos_theta ./ sin_theta_safe;
        
        % ==================================================================
        % 8. СДВИГИ ГУСА-ХЕНХЕН (GH) — ПРОСТРАНСТВЕННЫЕ
        % ==================================================================
        % Базовые сдвиги для собственных мод
        GH_s_spatial = factor_spatial .* dPhi_s;
        GH_p_spatial = factor_spatial .* dPhi_p;
        
        % Для циркулярных: ВЗВЕШЕННОЕ СРЕДНЕЕ по интенсивности (не по фазе!)
        GH_rcp_spatial = W_s .* GH_s_spatial + W_p .* GH_p_spatial;
        GH_lcp_spatial = W_s .* GH_s_spatial + W_p .* GH_p_spatial;
        
        % Сборка в ячейки для удобного построения графиков
        Delta_GH_norm = {GH_s_spatial / lambda0, GH_p_spatial / lambda0, GH_rcp_spatial / lambda0, GH_lcp_spatial / lambda0};
        
        % ==================================================================
        % 9. СДВИГИ ИМБЕРТА-ФЁДОРОВА (IF) — ПРОСТРАНСТВЕННЫЕ
        % ==================================================================
        % Базовый вклад (фазовый градиент)
        IF_base_spatial = (cot_theta ./ (k0 * n1)) .* dDelta_Phi;
        
        % Для линейных поляризаций в изотропных средах IF = 0
        IF_s_spatial = zeros(size(theta));
        IF_p_spatial = zeros(size(theta));
        
        % Для циркулярных: с учётом параметра Стокса S3 (эллиптичность)
        % Знак зависит от хиральности: +1 для RCP, -1 для LCP
        IF_rcp_spatial = -IF_base_spatial .* S3;  % sigma = +1
        IF_lcp_spatial = +IF_base_spatial .* S3;  % sigma = -1
        
        Delta_IF_norm = {IF_s_spatial / lambda0, IF_p_spatial / lambda0, IF_rcp_spatial / lambda0, IF_lcp_spatial / lambda0};
        
        % ==================================================================
        % 10. УГЛОВЫЕ СДВИГИ ГУСА-ХЕНХЕН
        % ==================================================================
        GH_s_angular = factor_angular .* dlnAmp_s;
        GH_p_angular = factor_angular .* dlnAmp_p;
        GH_rcp_angular = W_s .* GH_s_angular + W_p .* GH_p_angular;
        GH_lcp_angular = W_s .* GH_s_angular + W_p .* GH_p_angular;
        
        Theta_GH = {GH_s_angular, GH_p_angular, GH_rcp_angular, GH_lcp_angular};
        
        % ==================================================================
        % 11. УГЛОВЫЕ СДВИГИ ИМБЕРТА-ФЁДОРОВА
        % ==================================================================
        IF_base_angular = factor_angular .* cot_theta .* dAmp_diff;
        
        IF_s_angular = zeros(size(theta));
        IF_p_angular = zeros(size(theta));
        IF_rcp_angular = +IF_base_angular .* S3;   % sigma = +1
        IF_lcp_angular = -IF_base_angular .* S3;   % sigma = -1
        
        Theta_IF = {IF_s_angular, IF_p_angular, IF_rcp_angular, IF_lcp_angular};
        
        % ==================================================================
        % 12. ОБРАБОТКА ГРАНИЧНЫХ СЛУЧАЕВ
        % ==================================================================
        % При нормальном падении (theta -> 0) IF сдвиги отсутствуют
        idx_normal = abs(sin_theta) < 1e-3;
        for i = 1:4
            Delta_IF_norm{i}(idx_normal) = 0;
            Theta_IF{i}(idx_normal) = 0;
        end
        
        % При скользящем падении (theta -> 90°) cot_theta -> 0, но для надёжности
        idx_grazing = abs(cos_theta) < 1e-3;
        for i = 1:4
            Delta_IF_norm{i}(idx_grazing) = 0;
            Theta_IF{i}(idx_grazing) = 0;
        end
        
        % ==================================================================
        % 13. НАСТРОЙКИ ДЛЯ ПОСТРОЕНИЯ ГРАФИКОВ
        % ==================================================================
        pol = {'s', 'p', 'RCP', 'LCP'};
        pol_colors = {[0, 0.4470, 0.7410], [0.8500, 0.3250, 0.0980], ...
            [0, 0.6110, 0.3880], [0.6350, 0.0780, 0.1840]};
        pol_names = {'s-поляризация (TE)', 'p-поляризация (TM)', ...
            'Правая циркулярная (RCP)', 'Левая циркулярная (LCP)'};
        
        % ==================================================================
        % 14. ПОСТРОЕНИЕ ГРАФИКОВ
        % ==================================================================
        if show_fig1
            create_gh_spatial_figure(theta_deg, Delta_GH_norm, pol, pol_colors, pol_names);
        end
        if show_fig2
            create_if_spatial_figure(theta_deg, Delta_IF_norm, pol, pol_colors, pol_names);
        end
        if show_fig3
            create_gh_angular_figure(theta_deg, Theta_GH, pol, pol_colors, pol_names);
        end
        if show_fig4
            create_if_angular_figure(theta_deg, Theta_IF, pol, pol_colors, pol_names);
        end
        
        fprintf('✓ Расчёт выполнен успешно!\n');
        
    catch ME
        fprintf('✗ ОШИБКА в calculate_and_plot: %s\n', ME.message);
        fprintf('  Stack: %s\n', ME.stack(1).name);
    end
end

% ======================================================================
% ФУНКЦИИ ПОСТРОЕНИЯ ГРАФИКОВ (без изменений)
% ======================================================================
function create_gh_spatial_figure(theta_deg, Delta_GH_norm, pol, pol_colors, pol_names)
    figure('Name', 'Пространственные сдвиги GH', 'Color', 'w', 'Position', [50, 50, 1600, 1200]);
    subplot(3, 3, 1);
    hold on;
    for i = 1:4
        plot(theta_deg, Delta_GH_norm{i}, 'Color', pol_colors{i}, 'LineWidth', 2);
    end
    yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
    xlabel('Угол падения \theta (град)'); ylabel('D_{GH} / \lambda_0');
    title('Все поляризации'); legend({sprintf('GH (%s)', pol{1}), sprintf('GH (%s)', pol{2}), ...
        sprintf('GH (%s)', pol{3}), sprintf('GH (%s)', pol{4})}, 'Location', 'best');
    xlim([min(theta_deg), max(theta_deg)]); ylim_auto();
    for p = 1:4
        subplot(3, 3, 1+p);
        plot(theta_deg, Delta_GH_norm{p}, 'Color', pol_colors{p}, 'LineWidth', 2.5);
        yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
        xlabel('Угол падения \theta (град)'); ylabel('D_{GH} / \lambda_0');
        title(pol_names{p}); xlim([min(theta_deg), max(theta_deg)]); ylim_auto();
    end
    subplot(3, 3, 7);
    plot(theta_deg, Delta_GH_norm{1}, 'Color', pol_colors{1}, 'LineWidth', 2, 'DisplayName', 'GH (s)');
    hold on;
    plot(theta_deg, Delta_GH_norm{2}, 'Color', pol_colors{2}, 'LineWidth', 2, 'DisplayName', 'GH (p)');
    yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
    xlabel('Угол падения \theta (град)'); ylabel('D_{GH} / \lambda_0');
    title('Сравнение: s vs p'); legend('Location', 'best');
    xlim([min(theta_deg), max(theta_deg)]); ylim_auto();
    subplot(3, 3, 8);
    plot(theta_deg, Delta_GH_norm{3}, 'Color', pol_colors{3}, 'LineWidth', 2, 'DisplayName', 'GH (RCP)');
    hold on;
    plot(theta_deg, Delta_GH_norm{4}, 'Color', pol_colors{4}, 'LineWidth', 2, 'DisplayName', 'GH (LCP)');
    yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
    xlabel('Угол падения \theta (град)'); ylabel('D_{GH} / \lambda_0');
    title('Сравнение: RCP vs LCP'); legend('Location', 'best');
    xlim([min(theta_deg), max(theta_deg)]); ylim_auto();
    subplot(3, 3, 9);
    axis off;
    text(0.1, 0.5, {'ЭФФЕКТ ГУСА-ХЕНХЕН', 'Пространственный сдвиг', 'в плоскости падения', ...
        ' ', 'Синий - s', 'Оранжевый - p', 'Зелёный - RCP', 'Бордовый - LCP'}, ...
        'FontSize', 11, 'FontWeight', 'bold');
end

function create_if_spatial_figure(theta_deg, Delta_IF_norm, pol, pol_colors, pol_names)
    figure('Name', 'Пространственные сдвиги IF', 'Color', 'w', 'Position', [50, 50, 1600, 1200]);
    subplot(3, 3, 1);
    hold on;
    for i = 1:4
        plot(theta_deg, Delta_IF_norm{i}, 'Color', pol_colors{i}, 'LineWidth', 2);
    end
    yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
    xlabel('Угол падения \theta (град)'); ylabel('D_{IF} / \lambda_0');
    title('Все поляризации'); legend({sprintf('IF (%s)', pol{1}), sprintf('IF (%s)', pol{2}), ...
        sprintf('IF (%s)', pol{3}), sprintf('IF (%s)', pol{4})}, 'Location', 'best');
    xlim([min(theta_deg), max(theta_deg)]); ylim_auto();
    for p = 1:4
        subplot(3, 3, 1+p);
        plot(theta_deg, Delta_IF_norm{p}, 'Color', pol_colors{p}, 'LineWidth', 2.5);
        yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
        xlabel('Угол падения \theta (град)'); ylabel('D_{IF} / \lambda_0');
        title(pol_names{p}); xlim([min(theta_deg), max(theta_deg)]); ylim_auto();
    end
    subplot(3, 3, 7);
    plot(theta_deg, Delta_IF_norm{1}, 'Color', pol_colors{1}, 'LineWidth', 2, 'DisplayName', 'IF (s)');
    hold on;
    plot(theta_deg, Delta_IF_norm{2}, 'Color', pol_colors{2}, 'LineWidth', 2, 'DisplayName', 'IF (p)');
    yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
    xlabel('Угол падения \theta (град)'); ylabel('D_{IF} / \lambda_0');
    title('Сравнение: s vs p (нулевые)'); legend('Location', 'best');
    xlim([min(theta_deg), max(theta_deg)]); ylim([-0.1, 0.1]);
    subplot(3, 3, 8);
    plot(theta_deg, Delta_IF_norm{3}, 'Color', pol_colors{3}, 'LineWidth', 2, 'DisplayName', 'IF (RCP)');
    hold on;
    plot(theta_deg, Delta_IF_norm{4}, 'Color', pol_colors{4}, 'LineWidth', 2, 'DisplayName', 'IF (LCP)');
    yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
    xlabel('Угол падения \theta (град)'); ylabel('D_{IF} / \lambda_0');
    title('Сравнение: RCP vs LCP'); legend('Location', 'best');
    xlim([min(theta_deg), max(theta_deg)]); ylim_auto();
    subplot(3, 3, 9);
    axis off;
    text(0.1, 0.5, {'ЭФФЕКТ ИМБЕРТА-ФЕДОРОВА', 'Поперечный сдвиг', 'перпендикулярно плоскости', ...
        ' ', 'RCP и LCP имеют', 'противоположные знаки'}, ...
        'FontSize', 11, 'FontWeight', 'bold');
end

function create_gh_angular_figure(theta_deg, Theta_GH, pol, pol_colors, pol_names)
    figure('Name', 'Угловые сдвиги GH', 'Color', 'w', 'Position', [50, 50, 1600, 1200]);
    subplot(3, 3, 1);
    hold on;
    for i = 1:4
        plot(theta_deg, Theta_GH{i} * 1e6, 'Color', pol_colors{i}, 'LineWidth', 2);
    end
    yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
    xlabel('Угол падения \theta (град)'); ylabel('\Theta_{GH} (мкрад)');
    title('Все поляризации'); legend({sprintf('GH (%s)', pol{1}), sprintf('GH (%s)', pol{2}), ...
        sprintf('GH (%s)', pol{3}), sprintf('GH (%s)', pol{4})}, 'Location', 'best');
    xlim([min(theta_deg), max(theta_deg)]); ylim_auto();
    for p = 1:4
        subplot(3, 3, 1+p);
        plot(theta_deg, Theta_GH{p} * 1e6, 'Color', pol_colors{p}, 'LineWidth', 2.5);
        yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
        xlabel('Угол падения \theta (град)'); ylabel('\Theta_{GH} (мкрад)');
        title(pol_names{p}); xlim([min(theta_deg), max(theta_deg)]); ylim_auto();
    end
    subplot(3, 3, 7);
    plot(theta_deg, Theta_GH{1} * 1e6, 'Color', pol_colors{1}, 'LineWidth', 2, 'DisplayName', 'Угл. GH (s)');
    hold on;
    plot(theta_deg, Theta_GH{2} * 1e6, 'Color', pol_colors{2}, 'LineWidth', 2, 'DisplayName', 'Угл. GH (p)');
    yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
    xlabel('Угол падения \theta (град)'); ylabel('\Theta_{GH} (мкрад)');
    title('Сравнение: s vs p'); legend('Location', 'best');
    xlim([min(theta_deg), max(theta_deg)]); ylim_auto();
    subplot(3, 3, 8);
    plot(theta_deg, Theta_GH{3} * 1e6, 'Color', pol_colors{3}, 'LineWidth', 2, 'DisplayName', 'Угл. GH (RCP)');
    hold on;
    plot(theta_deg, Theta_GH{4} * 1e6, 'Color', pol_colors{4}, 'LineWidth', 2, 'DisplayName', 'Угл. GH (LCP)');
    yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
    xlabel('Угол падения \theta (град)'); ylabel('\Theta_{GH} (мкрад)');
    title('Сравнение: RCP vs LCP'); legend('Location', 'best');
    xlim([min(theta_deg), max(theta_deg)]); ylim_auto();
    subplot(3, 3, 9);
    axis off;
    text(0.1, 0.5, {'УГЛОВОЙ ЭФФЕКТ ГУСА-ХЕНХЕН', 'Изменение угла отражения', 'в плоскости падения', ...
        ' ', 'Зависит от d(ln|R|)/d\theta', 'Максимален вблизи угла Брюстера'}, ...
        'FontSize', 11, 'FontWeight', 'bold');
end

function create_if_angular_figure(theta_deg, Theta_IF, pol, pol_colors, pol_names)
    figure('Name', 'Угловые сдвиги IF', 'Color', 'w', 'Position', [50, 50, 1600, 1200]);
    subplot(3, 3, 1);
    hold on;
    for i = 1:4
        plot(theta_deg, Theta_IF{i} * 1e6, 'Color', pol_colors{i}, 'LineWidth', 2);
    end
    yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
    xlabel('Угол падения \theta (град)'); ylabel('\Theta_{IF} (мкрад)');
    title('Все поляризации'); legend({sprintf('IF (%s)', pol{1}), sprintf('IF (%s)', pol{2}), ...
        sprintf('IF (%s)', pol{3}), sprintf('IF (%s)', pol{4})}, 'Location', 'best');
    xlim([min(theta_deg), max(theta_deg)]); ylim_auto();
    for p = 1:4
        subplot(3, 3, 1+p);
        plot(theta_deg, Theta_IF{p} * 1e6, 'Color', pol_colors{p}, 'LineWidth', 2.5);
        yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
        xlabel('Угол падения \theta (град)'); ylabel('\Theta_{IF} (мкрад)');
        title(pol_names{p}); xlim([min(theta_deg), max(theta_deg)]); ylim_auto();
    end
    subplot(3, 3, 7);
    plot(theta_deg, Theta_IF{1} * 1e6, 'Color', pol_colors{1}, 'LineWidth', 2, 'DisplayName', 'Угл. IF (s)');
    hold on;
    plot(theta_deg, Theta_IF{2} * 1e6, 'Color', pol_colors{2}, 'LineWidth', 2, 'DisplayName', 'Угл. IF (p)');
    yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
    xlabel('Угол падения \theta (град)'); ylabel('\Theta_{IF} (мкрад)');
    title('Сравнение: s vs p (нулевые)'); legend('Location', 'best');
    xlim([min(theta_deg), max(theta_deg)]); ylim([-0.1, 0.1]);
    subplot(3, 3, 8);
    plot(theta_deg, Theta_IF{3} * 1e6, 'Color', pol_colors{3}, 'LineWidth', 2, 'DisplayName', 'Угл. IF (RCP)');
    hold on;
    plot(theta_deg, Theta_IF{4} * 1e6, 'Color', pol_colors{4}, 'LineWidth', 2, 'DisplayName', 'Угл. IF (LCP)');
    yline(0, 'k:', 'DisplayName', 'Нулевой уровень'); grid on;
    xlabel('Угол падения \theta (град)'); ylabel('\Theta_{IF} (мкрад)');
    title('Сравнение: RCP vs LCP'); legend('Location', 'best');
    xlim([min(theta_deg), max(theta_deg)]); ylim_auto();
    subplot(3, 3, 9);
    axis off;
    text(0.1, 0.5, {'УГЛОВОЙ ЭФФЕКТ ИМБЕРТА-ФЕДОРОВА', 'Изменение угла отражения', 'перпендикулярно плоскости', ...
        ' ', 'Проявляется для', 'циркулярных поляризаций'}, ...
        'FontSize', 11, 'FontWeight', 'bold');
end

function [eps, mu] = drude_lorentz_model(omega, layer)
    eps = layer.eps_inf;
    if layer.eps_drude.omega_p > 0
        eps = eps - (layer.eps_drude.omega_p^2) / (omega^2 + 1i * layer.eps_drude.gamma * omega);
    end
    if ~isempty(layer.eps_lorentz)
        eps = eps + (layer.eps_lorentz.f * layer.eps_lorentz.omega_0^2) / ...
            (layer.eps_lorentz.omega_0^2 - omega^2 - 1i * layer.eps_lorentz.Gamma * omega);
    end
    mu = layer.mu_inf;
    if layer.mu_drude.omega_p > 0
        mu = mu - (layer.mu_drude.omega_p^2) / (omega^2 + 1i * layer.mu_drude.gamma * omega);
    end
    if ~isempty(layer.mu_lorentz)
        mu = mu + (layer.mu_lorentz.f * layer.mu_lorentz.omega_0^2) / ...
            (layer.mu_lorentz.omega_0^2 - omega^2 - 1i * layer.mu_lorentz.Gamma * omega);
    end
end

function ylim_auto()
    yl = ylim; y_range = yl(2) - yl(1);
    if y_range < 1e-10, y_range = 1; yl(1) = -0.5; yl(2) = 0.5; end
    padding = y_range * 0.05;
    ylim([yl(1) - padding, yl(2) + padding]);
end

% ======================================================================
% ПРОДВИНУТЫЕ ГРАФИКИ
% ======================================================================
function start_advanced_calculation_callback(~, ~)
    app_data = get_app_data();
    old_adv_windows = findall(0, 'Name', 'Продвинутые графики - Настройка');
    if ~isempty(old_adv_windows)
        close(old_adv_windows);
    end
    old_result_windows = findall(0, 'Name', 'Сдвиг от');
    if ~isempty(old_result_windows)
        close(old_result_windows);
    end
    create_advanced_graphics_window(app_data);
end

function create_advanced_graphics_window(app_data)
    old_adv = findall(0, 'Name', 'Продвинутые графики - Настройка');
    if ~isempty(old_adv)
        close(old_adv);
    end
    h_adv = figure('Name', 'Продвинутые графики - Настройка', ...
        'Position', [300, 150, 750, 900], ...  % === УВЕЛИЧЕНА ВЫСОТА ===
        'MenuBar', 'none', 'ToolBar', 'none', ...
        'NumberTitle', 'off', 'Resize', 'off', ...
        'Color', [0.95, 0.95, 0.95]);
    
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'ПРОДВИНУТЫЕ ГРАФИКИ - ГИБКИЙ ВЫБОР ПАРАМЕТРОВ', ...
        'FontSize', 13, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
        'Position', [20, 850, 710, 40]);
    uipanel('Parent', h_adv, 'Position', [20, 830, 710, 2], ...
        'BackgroundColor', [0.3, 0.3, 0.3], 'BorderType', 'none');
    
    % ==================================================================
    % ТИП ГРАФИКА
    % ==================================================================
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'ТИП ГРАФИКА (можно выбрать оба)', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'Position', [20, 790, 710, 25]);
    app_data.adv_graph_2d = uicontrol('Parent', h_adv, ...
        'Style', 'checkbox', 'String', '2D график (один параметр)', ...
        'Position', [20, 760, 250, 25], 'Value', 1, 'FontSize', 10, ...
        'Tag', 'adv_graph_2d', 'Callback', @toggle_graph_type_callback);
    app_data.adv_graph_3d = uicontrol('Parent', h_adv, ...
        'Style', 'checkbox', 'String', '3D график (два параметра)', ...
        'Position', [280, 760, 250, 25], 'Value', 0, 'FontSize', 10, ...
        'Tag', 'adv_graph_3d', 'Callback', @toggle_graph_type_callback);
    
    % ==================================================================
    % === НОВОЕ: ТОЧНОСТЬ РАСЧЁТА (количество точек по углу) ===
    % ==================================================================
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'ТОЧНОСТЬ РАСЧЁТА', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'Position', [20, 725, 710, 25]);
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Точек по углу:', ...
        'Position', [20, 695, 100, 25]);
    app_data.adv_n_angle_points = uicontrol('Parent', h_adv, ...
        'Style', 'edit', 'String', '5000', ...
        'Position', [130, 695, 80, 25], ...
        'FontSize', 10, 'Tag', 'adv_n_angle_points', ...
        'TooltipString', 'Количество точек для расчёта градиента. Больше = точнее, но медленнее.');
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', '(1000-50000)', ...
        'Position', [220, 695, 100, 25], 'FontSize', 9);
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', '⚠ Больше точек = выше точность, но медленнее расчёт', ...
        'Position', [20, 670, 400, 20], 'FontSize', 8, 'ForegroundColor', [0.8, 0.4, 0]);
    uipanel('Parent', h_adv, 'Position', [20, 650, 710, 2], ...
        'BackgroundColor', [0.5, 0.5, 0.5], 'BorderType', 'none');
    
    % ==================================================================
    % ПАРАМЕТР 1
    % ==================================================================
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'ПАРАМЕТР 1 (Ось X)', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'Position', [20, 615, 710, 25]);
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Категория:', 'Position', [20, 585, 70, 25]);
    app_data.adv_param1_category = uicontrol('Parent', h_adv, ...
        'Style', 'popupmenu', ...
        'String', {'Излучение'; 'Среда (толщина)'; 'Среда (свойства)'}, ...
        'Position', [100, 585, 150, 25], 'FontSize', 10, ...
        'Tag', 'param1_category', 'Callback', @update_param1_subcategory_callback);
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Параметр:', 'Position', [270, 585, 70, 25], 'Tag', 'param1_subcat_label');
    app_data.adv_param1_subcategory = uicontrol('Parent', h_adv, ...
        'Style', 'popupmenu', ...
        'String', {'Длина волны'; 'Перетяжка w₀'; 'Угол падения'}, ...
        'Position', [350, 585, 150, 25], 'FontSize', 10, ...
        'Tag', 'param1_subcategory', 'Callback', @update_param1_details_callback);
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Слой:', 'Position', [520, 585, 40, 25], 'Tag', 'param1_layer_label', 'Visible', 'off');
    app_data.adv_param1_layer = uicontrol('Parent', h_adv, ...
        'Style', 'popupmenu', 'String', '', ...
        'Position', [570, 585, 80, 25], 'FontSize', 10, ...
        'Tag', 'param1_layer', 'Visible', 'off', 'Callback', @update_param1_property_callback);
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Свойство:', 'Position', [270, 555, 70, 25], 'Tag', 'param1_property_label', 'Visible', 'off');
    app_data.adv_param1_property = uicontrol('Parent', h_adv, ...
        'Style', 'popupmenu', 'String', '', ...
        'Position', [350, 555, 200, 25], 'FontSize', 10, ...
        'Tag', 'param1_property', 'Visible', 'off');
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Тип:', 'Position', [570, 555, 40, 25], 'Tag', 'param1_mattype_label', 'Visible', 'off');
    app_data.adv_param1_mattype = uicontrol('Parent', h_adv, ...
        'Style', 'popupmenu', 'String', {'Постоянный'; 'Друде'; 'Лоренц'}, ...
        'Position', [620, 555, 100, 25], 'FontSize', 10, ...
        'Tag', 'param1_mattype', 'Visible', 'off', ...
        'Callback', @update_param1_mattype_callback);
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Диапазон:', 'Position', [20, 525, 70, 25]);
    app_data.adv_param1_min = uicontrol('Parent', h_adv, ...
        'Style', 'edit', 'String', '10', 'Position', [100, 525, 50, 25], ...
        'FontSize', 10, 'Tag', 'param1_min');
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'от', 'Position', [160, 525, 30, 25]);
    app_data.adv_param1_max = uicontrol('Parent', h_adv, ...
        'Style', 'edit', 'String', '500', 'Position', [200, 525, 50, 25], ...
        'FontSize', 10, 'Tag', 'param1_max');
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'до', 'Position', [260, 525, 30, 25]);
    app_data.adv_param1_step = uicontrol('Parent', h_adv, ...
        'Style', 'edit', 'String', '10', 'Position', [300, 525, 50, 25], ...
        'FontSize', 10, 'Tag', 'param1_step');
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'шаг', 'Position', [360, 525, 40, 25]);
    app_data.adv_param1_unit = uicontrol('Parent', h_adv, ...
        'Style', 'text', 'String', '(нм)', 'Position', [410, 525, 50, 25], ...
        'FontSize', 9, 'Tag', 'param1_unit');
    uipanel('Parent', h_adv, 'Position', [20, 505, 710, 2], ...
        'BackgroundColor', [0.5, 0.5, 0.5], 'BorderType', 'none');
    
    % ==================================================================
    % ПАРАМЕТР 2 (для 3D)
    % ==================================================================
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'ПАРАМЕТР 2 (Ось Y) - только для 3D', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'Position', [20, 470, 710, 25], 'Tag', 'param2_header', 'Visible', 'off');
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Категория:', 'Position', [20, 440, 70, 25], ...
        'Tag', 'param2_cat_label', 'Visible', 'off');
    app_data.adv_param2_category = uicontrol('Parent', h_adv, ...
        'Style', 'popupmenu', ...
        'String', {'Излучение'; 'Среда (толщина)'; 'Среда (свойства)'}, ...
        'Position', [100, 440, 150, 25], 'FontSize', 10, ...
        'Tag', 'param2_category', 'Callback', @update_param2_subcategory_callback, 'Visible', 'off');
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Параметр:', 'Position', [270, 440, 70, 25], ...
        'Tag', 'param2_subcat_label', 'Visible', 'off');
    app_data.adv_param2_subcategory = uicontrol('Parent', h_adv, ...
        'Style', 'popupmenu', ...
        'String', {'Длина волны'; 'Перетяжка w₀'; 'Угол падения'}, ...
        'Position', [350, 440, 150, 25], 'FontSize', 10, ...
        'Tag', 'param2_subcategory', 'Callback', @update_param2_details_callback, 'Visible', 'off');
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Слой:', 'Position', [520, 440, 40, 25], ...
        'Tag', 'param2_layer_label', 'Visible', 'off');
    app_data.adv_param2_layer = uicontrol('Parent', h_adv, ...
        'Style', 'popupmenu', 'String', '', ...
        'Position', [570, 440, 80, 25], 'FontSize', 10, ...
        'Tag', 'param2_layer', 'Visible', 'off', 'Callback', @update_param2_property_callback);
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Свойство:', 'Position', [270, 410, 70, 25], ...
        'Tag', 'param2_property_label', 'Visible', 'off');
    app_data.adv_param2_property = uicontrol('Parent', h_adv, ...
        'Style', 'popupmenu', 'String', '', ...
        'Position', [350, 410, 200, 25], 'FontSize', 10, ...
        'Tag', 'param2_property', 'Visible', 'off');
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Тип:', 'Position', [570, 410, 40, 25], ...
        'Tag', 'param2_mattype_label', 'Visible', 'off');
    app_data.adv_param2_mattype = uicontrol('Parent', h_adv, ...
        'Style', 'popupmenu', 'String', {'Постоянный'; 'Друде'; 'Лоренц'}, ...
        'Position', [620, 410, 100, 25], 'FontSize', 10, ...
        'Tag', 'param2_mattype', 'Visible', 'off', ...
        'Callback', @update_param2_mattype_callback);
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Диапазон:', 'Position', [20, 380, 70, 25], ...
        'Tag', 'param2_range_label', 'Visible', 'off');
    app_data.adv_param2_min = uicontrol('Parent', h_adv, ...
        'Style', 'edit', 'String', '10', 'Position', [100, 380, 50, 25], ...
        'FontSize', 10, 'Tag', 'param2_min', 'Visible', 'off');
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'от', 'Position', [160, 380, 30, 25], ...
        'Tag', 'param2_from_label', 'Visible', 'off');
    app_data.adv_param2_max = uicontrol('Parent', h_adv, ...
        'Style', 'edit', 'String', '500', 'Position', [200, 380, 50, 25], ...
        'FontSize', 10, 'Tag', 'param2_max', 'Visible', 'off');
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'до', 'Position', [260, 380, 30, 25], ...
        'Tag', 'param2_to_label', 'Visible', 'off');
    app_data.adv_param2_step = uicontrol('Parent', h_adv, ...
        'Style', 'edit', 'String', '20', 'Position', [300, 380, 50, 25], ...
        'FontSize', 10, 'Tag', 'param2_step', 'Visible', 'off');
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'шаг', 'Position', [360, 380, 40, 25], ...
        'Tag', 'param2_step_label', 'Visible', 'off');
    app_data.adv_param2_unit = uicontrol('Parent', h_adv, ...
        'Style', 'text', 'String', '(нм)', 'Position', [410, 380, 50, 25], ...
        'FontSize', 9, 'Tag', 'param2_unit', 'Visible', 'off');
    
    % ==================================================================
    % ФИКСИРОВАННЫЕ ПАРАМЕТРЫ
    % ==================================================================
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'ФИКСИРОВАННЫЕ ПАРАМЕТРЫ (не варьируются)', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'Position', [20, 325, 710, 25]);
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Длина волны (нм):', 'Position', [20, 295, 130, 25]);
    app_data.adv_lambda_edit = uicontrol('Parent', h_adv, ...
        'Style', 'edit', 'String', '632.8', 'Position', [160, 295, 70, 25], ...
        'FontSize', 10, 'Tag', 'adv_lambda_edit');
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Перетяжка w₀ (мкм):', 'Position', [260, 295, 130, 25]);
    app_data.adv_w0_edit = uicontrol('Parent', h_adv, ...
        'Style', 'edit', 'String', '20', 'Position', [400, 295, 60, 25], ...
        'FontSize', 10, 'Tag', 'adv_w0_edit');
    uicontrol('Parent', h_adv, 'Style', 'text', ...
        'String', 'Угол падения (град):', 'Position', [20, 265, 130, 25]);
    app_data.adv_theta_edit = uicontrol('Parent', h_adv, ...
        'Style', 'edit', 'String', '45', 'Position', [160, 265, 70, 25], ...
        'FontSize', 10, 'Tag', 'adv_theta_edit');
    
 % ======================================================================
% ПОЛЯРИЗАЦИЯ И ТИП СДВИГА (ИЗМЕНЁННАЯ ВЕРСИЯ - ЧЕКБОКСЫ)
% ======================================================================
uicontrol('Parent', h_adv, 'Style', 'text', ...
    'String', 'ПОЛЯРИЗАЦИЯ', ...
    'FontSize', 11, 'FontWeight', 'bold', ...
    'Position', [20, 230, 710, 25]);
uicontrol('Parent', h_adv, 'Style', 'text', ...
    'String', 'Поляризация:', 'Position', [20, 200, 80, 25], 'FontSize', 10);
app_data.adv_pol_check = uicontrol('Parent', h_adv, ...
    'Style', 'checkbox', 'String', 's', ...
    'Position', [110, 200, 40, 25], 'Value', 1, 'FontSize', 10, ...
    'Tag', 'adv_pol_check');
app_data.adv_pol_check2 = uicontrol('Parent', h_adv, ...
    'Style', 'checkbox', 'String', 'p', ...
    'Position', [155, 200, 40, 25], 'Value', 0, 'FontSize', 10, ...
    'Tag', 'adv_pol_check2');
app_data.adv_pol_check3 = uicontrol('Parent', h_adv, ...
    'Style', 'checkbox', 'String', 'RCP', ...
    'Position', [200, 200, 55, 25], 'Value', 0, 'FontSize', 10, ...
    'Tag', 'adv_pol_check3');
app_data.adv_pol_check4 = uicontrol('Parent', h_adv, ...
    'Style', 'checkbox', 'String', 'LCP', ...
    'Position', [260, 200, 55, 25], 'Value', 0, 'FontSize', 10, ...
    'Tag', 'adv_pol_check4');

% === ИЗМЕНЕНИЕ: ЧЕКБОКСЫ ДЛЯ ВСЕХ ТИПОВ СДВИГОВ ===
uicontrol('Parent', h_adv, 'Style', 'text', ...
    'String', 'ТИПЫ СДВИГОВ (можно выбрать несколько):', ...
    'Position', [350, 230, 250, 25], 'FontSize', 10, 'FontWeight', 'bold');
app_data.adv_shift_gh_spatial = uicontrol('Parent', h_adv, ...
    'Style', 'checkbox', 'String', 'Простр. GH', ...
    'Position', [350, 200, 90, 25], 'Value', 1, 'FontSize', 10, ...
    'Tag', 'adv_shift_gh_spatial');
app_data.adv_shift_if_spatial = uicontrol('Parent', h_adv, ...
    'Style', 'checkbox', 'String', 'Простр. IF', ...
    'Position', [445, 200, 90, 25], 'Value', 1, 'FontSize', 10, ...
    'Tag', 'adv_shift_if_spatial');
app_data.adv_shift_gh_angular = uicontrol('Parent', h_adv, ...
    'Style', 'checkbox', 'String', 'Угловой GH', ...
    'Position', [540, 200, 90, 25], 'Value', 1, 'FontSize', 10, ...
    'Tag', 'adv_shift_gh_angular');
app_data.adv_shift_if_angular = uicontrol('Parent', h_adv, ...
    'Style', 'checkbox', 'String', 'Угловой IF', ...
    'Position', [635, 200, 90, 25], 'Value', 1, 'FontSize', 10, ...
    'Tag', 'adv_shift_if_angular');
    
    % ==================================================================
    % КНОПКИ
    % ==================================================================
    app_data.adv_build_button = uicontrol('Parent', h_adv, ...
        'Style', 'pushbutton', ...
        'String', '📊 ПОСТРОИТЬ ГРАФИКИ', ...
        'Position', [20, 140, 710, 50], ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.2, 0.6, 0.2], ...
        'ForegroundColor', [1, 1, 1], ...
        'Callback', @build_advanced_graphics_callback);
    uicontrol('Parent', h_adv, 'Style', 'pushbutton', ...
        'String', 'ОТМЕНА', ...
        'Position', [20, 100, 710, 35], ...
        'FontSize', 11, ...
        'Callback', @(src,~) close(gcbf));
    
    app_data.adv_status = uicontrol('Parent', h_adv, ...
        'Style', 'text', 'String', 'Готов к построению', ...
        'Position', [20, 80, 710, 15], ...
        'FontSize', 9, 'HorizontalAlignment', 'center', ...
        'ForegroundColor', [0, 0.5, 0], 'Tag', 'adv_status');
    app_data.adv_structure_info = uicontrol('Parent', h_adv, ...
        'Style', 'text', 'String', '', ...
        'Position', [20, 60, 710, 15], ...
        'FontSize', 8, 'HorizontalAlignment', 'center', ...
        'ForegroundColor', [0.3, 0.3, 0.3], 'Tag', 'adv_structure_info');
    
    N_layers = app_data.N_layers;
    layer_strings = cell(1, N_layers);
    for i = 1:N_layers
        layer_strings{i} = sprintf('Слой %d', i);
    end
    set(findobj(h_adv, 'Tag', 'param1_layer'), 'String', layer_strings);
    set(findobj(h_adv, 'Tag', 'param2_layer'), 'String', layer_strings);
    set(findobj(h_adv, 'Tag', 'param1_property'), 'String', {'Сначала выберите слой'});
    set(findobj(h_adv, 'Tag', 'param2_property'), 'String', {'Сначала выберите слой'});
    update_layer_lists(h_adv, N_layers, app_data);
    update_param1_subcategory_callback(app_data.adv_param1_category, []);
    toggle_graph_type_callback(app_data.adv_graph_2d, []);
    assignin('base', 'gh_if_adv_data', app_data);
end

% ======================================================================
% ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ПРОДВИНУТЫХ ГРАФИКОВ
% ======================================================================
function toggle_graph_type_callback(src, ~)
    h_adv = gcbf;
    h_2d = findobj(h_adv, 'Tag', 'adv_graph_2d');
    h_3d = findobj(h_adv, 'Tag', 'adv_graph_3d');
    is_2d = get(h_2d, 'Value');
    is_3d = get(h_3d, 'Value');
    h_param2_header = findobj(h_adv, 'Tag', 'param2_header');
    tags_param2 = {
        'param2_cat_label', 'param2_category', ...
        'param2_subcat_label', 'param2_subcategory', ...
        'param2_layer_label', 'param2_layer', ...
        'param2_property_label', 'param2_property', ...
        'param2_mattype_label', 'param2_mattype', ...
        'param2_range_label', 'param2_min', 'param2_from_label', ...
        'param2_max', 'param2_to_label', 'param2_step', ...
        'param2_step_label', 'param2_unit'
    };
    if is_3d
        set(h_param2_header, 'Visible', 'on');
        set(findobj(h_adv, 'Tag', 'param2_cat_label'), 'Visible', 'on');
        set(findobj(h_adv, 'Tag', 'param2_category'), 'Visible', 'on');
        set(findobj(h_adv, 'Tag', 'param2_subcat_label'), 'Visible', 'on');
        set(findobj(h_adv, 'Tag', 'param2_subcategory'), 'Visible', 'on');
        for i = 1:length(tags_param2)
            tag = tags_param2{i};
            if ~strcmp(tag, 'param2_cat_label') && ~strcmp(tag, 'param2_category') && ...
                    ~strcmp(tag, 'param2_subcat_label') && ~strcmp(tag, 'param2_subcategory')
                h = findobj(h_adv, 'Tag', tag);
                if ~isempty(h)
                    set(h(1), 'Visible', 'off');
                end
            end
        end
        set(findobj(h_adv, 'Tag', 'param2_category'), 'Value', 1);
        update_param2_subcategory_callback(findobj(h_adv, 'Tag', 'param2_category'), []);
    else
        set(h_param2_header, 'Visible', 'off');
        for i = 1:length(tags_param2)
            h = findobj(h_adv, 'Tag', tags_param2{i});
            if ~isempty(h)
                set(h(1), 'Visible', 'off');
            end
        end
    end
end

function update_layer_lists(h_adv, N_layers, app_data)
    layer_strings = cell(1, N_layers);
    for i = 1:N_layers
        if i <= N_layers && isfield(app_data, 'layers') && ~isempty(app_data.layers)
            layer_data = app_data.layers{i};
            if isinf(layer_data{13})
                thick_str = '∞';
            else
                thick_str = sprintf('%.0f нм', layer_data{13}*1e9);
            end
            if strcmp(layer_data{14}, 'constant')
                type_str = 'пост.';
            else
                type_str = 'дисп.';
            end
            layer_strings{i} = sprintf('Слой %d (%s)', i, type_str);
        else
            layer_strings{i} = sprintf('Слой %d', i);
        end
    end
    set(findobj(h_adv, 'Tag', 'param1_layer'), 'String', layer_strings);
    set(findobj(h_adv, 'Tag', 'param2_layer'), 'String', layer_strings);
end

% ======================================================================
% CALLBACK ФУНКЦИИ ДЛЯ ПАРАМЕТРОВ (без изменений)
% ======================================================================
function update_param1_subcategory_callback(src, ~)
    h_adv = gcbf;
    app_data = get_app_data();
    category = get(src, 'Value');
    h_subcat = findobj(h_adv, 'Tag', 'param1_subcategory');
    h_subcat_label = findobj(h_adv, 'Tag', 'param1_subcat_label');
    h_layer = findobj(h_adv, 'Tag', 'param1_layer');
    h_layer_label = findobj(h_adv, 'Tag', 'param1_layer_label');
    h_property = findobj(h_adv, 'Tag', 'param1_property');
    h_property_label = findobj(h_adv, 'Tag', 'param1_property_label');
    h_mattype = findobj(h_adv, 'Tag', 'param1_mattype');
    h_mattype_label = findobj(h_adv, 'Tag', 'param1_mattype_label');
    h_unit = findobj(h_adv, 'Tag', 'param1_unit');
    set(h_layer_label, 'Visible', 'off');
    set(h_layer, 'Visible', 'off');
    set(h_property_label, 'Visible', 'off');
    set(h_property, 'Visible', 'off');
    set(h_mattype_label, 'Visible', 'off');
    set(h_mattype, 'Visible', 'off');
    set(h_subcat_label, 'Visible', 'off');
    set(h_subcat, 'Visible', 'off');
    switch category
        case 1
            set(h_subcat_label, 'Visible', 'on');
            set(h_subcat, 'Visible', 'on');
            set(h_subcat, 'String', {'Длина волны'; 'Перетяжка w₀'; 'Угол падения'});
            set(h_subcat, 'Value', 1);
            update_param1_details_callback(h_subcat, []);
        case 2
            set(h_subcat_label, 'Visible', 'on');
            set(h_subcat, 'Visible', 'on');
            set(h_subcat, 'String', {'Толщина слоя'});
            set(h_subcat, 'Value', 1);
            set(h_layer_label, 'Visible', 'on');
            set(h_layer, 'Visible', 'on');
            set(h_unit, 'String', '(нм)');
            set(findobj(h_adv, 'Tag', 'param1_min'), 'String', '10');
            set(findobj(h_adv, 'Tag', 'param1_max'), 'String', '500');
            set(findobj(h_adv, 'Tag', 'param1_step'), 'String', '10');
        case 3
            set(h_subcat_label, 'Visible', 'on');
            set(h_subcat, 'Visible', 'on');
            set(h_subcat, 'String', {'Свойства материала'});
            set(h_subcat, 'Value', 1);
            set(h_layer_label, 'Visible', 'on');
            set(h_layer, 'Visible', 'on');
            set(h_mattype_label, 'Visible', 'on');
            set(h_mattype, 'Visible', 'on');
            set(h_mattype, 'String', {'Постоянный'; 'Друде'; 'Лоренц'});
            set(h_mattype, 'Value', 1);
            update_param1_property_callback(h_layer, []);
    end
end

function update_param1_details_callback(src, ~)
    h_adv = gcbf;
    category = get(findobj(h_adv, 'Tag', 'param1_category'), 'Value');
    subcategory = get(src, 'Value');
    h_unit = findobj(h_adv, 'Tag', 'param1_unit');
    if category == 1
        switch subcategory
            case 1
                set(h_unit, 'String', '(нм)');
                set(findobj(h_adv, 'Tag', 'param1_min'), 'String', '400');
                set(findobj(h_adv, 'Tag', 'param1_max'), 'String', '800');
                set(findobj(h_adv, 'Tag', 'param1_step'), 'String', '10');
            case 2
                set(h_unit, 'String', '(мкм)');
                set(findobj(h_adv, 'Tag', 'param1_min'), 'String', '5');
                set(findobj(h_adv, 'Tag', 'param1_max'), 'String', '50');
                set(findobj(h_adv, 'Tag', 'param1_step'), 'String', '1');
            case 3
                set(h_unit, 'String', '(град)');
                set(findobj(h_adv, 'Tag', 'param1_min'), 'String', '1');
                set(findobj(h_adv, 'Tag', 'param1_max'), 'String', '89');
                set(findobj(h_adv, 'Tag', 'param1_step'), 'String', '1');
        end
    end
end

function update_param1_property_callback(src, ~)
    h_adv = gcbf;
    app_data = get_app_data();
    h_category = findobj(h_adv, 'Tag', 'param1_category');
    category = get(h_category, 'Value');
    if category ~= 3
        return;
    end
    h_layer = findobj(h_adv, 'Tag', 'param1_layer');
    h_mattype = findobj(h_adv, 'Tag', 'param1_mattype');
    h_mattype_label = findobj(h_adv, 'Tag', 'param1_mattype_label');
    layer_idx = get(h_layer, 'Value');
    h_property = findobj(h_adv, 'Tag', 'param1_property');
    h_property_label = findobj(h_adv, 'Tag', 'param1_property_label');
    h_unit = findobj(h_adv, 'Tag', 'param1_unit');
    if isempty(layer_idx)
        return;
    end
    if layer_idx <= app_data.N_layers
        layer_data = app_data.layers{layer_idx};
        is_constant = strcmp(layer_data{14}, 'constant');
        set(h_mattype_label, 'Visible', 'on');
        set(h_mattype, 'Visible', 'on');
        if is_constant
            set(h_mattype, 'String', {'Постоянный'});
            set(h_mattype, 'Value', 1);
            mattype = 1;
            props = {'Re(ε)'; 'Im(ε)'; 'Re(μ)'; 'Im(μ)'};
            set(h_unit, 'String', '(безр.)');
        else
            set(h_mattype, 'String', {'Друде'; 'Лоренц'});
            has_drude = (layer_data{2} > 0) || (layer_data{3} > 0) || ...
                (layer_data{8} > 0) || (layer_data{9} > 0);
            has_lorentz = (layer_data{4} > 0) || (layer_data{5} > 0) || ...
                (layer_data{10} > 0) || (layer_data{11} > 0);
            if has_drude && ~has_lorentz
                set(h_mattype, 'Value', 1);
            elseif has_lorentz && ~has_drude
                set(h_mattype, 'Value', 2);
            else
                set(h_mattype, 'Value', 1);
            end
            mattype = get(h_mattype, 'Value');
            switch mattype
                case 1
                    props = {'ωₚ (ε)'; 'γ (ε)'; 'ωₚ (μ)'; 'γ (μ)'};
                    set(h_unit, 'String', '(рад/с)');
                case 2
                    props = {'f (ε)'; 'ω₀ (ε)'; 'Γ (ε)'; 'f (μ)'; 'ω₀ (μ)'; 'Γ (μ)'};
                    set(h_unit, 'String', '(разная)');
            end
        end
        set(h_property, 'String', props);
        set(h_property_label, 'Visible', 'on');
        set(h_property, 'Visible', 'on');
        set(h_property, 'Callback', {@update_unit_on_property_change, 1});
    end
end

function update_param2_details_callback(src, ~)
    h_adv = gcbf;
    category = get(findobj(h_adv, 'Tag', 'param2_category'), 'Value');
    subcategory = get(src, 'Value');
    h_unit = findobj(h_adv, 'Tag', 'param2_unit');
    if category == 1
        switch subcategory
            case 1
                set(h_unit, 'String', '(нм)');
                set(findobj(h_adv, 'Tag', 'param2_min'), 'String', '400');
                set(findobj(h_adv, 'Tag', 'param2_max'), 'String', '800');
                set(findobj(h_adv, 'Tag', 'param2_step'), 'String', '10');
            case 2
                set(h_unit, 'String', '(мкм)');
                set(findobj(h_adv, 'Tag', 'param2_min'), 'String', '5');
                set(findobj(h_adv, 'Tag', 'param2_max'), 'String', '50');
                set(findobj(h_adv, 'Tag', 'param2_step'), 'String', '1');
            case 3
                set(h_unit, 'String', '(град)');
                set(findobj(h_adv, 'Tag', 'param2_min'), 'String', '1');
                set(findobj(h_adv, 'Tag', 'param2_max'), 'String', '89');
                set(findobj(h_adv, 'Tag', 'param2_step'), 'String', '1');
        end
    end
end

function update_param2_property_callback(src, ~)
    h_adv = gcbf;
    app_data = get_app_data();
    h_category = findobj(h_adv, 'Tag', 'param2_category');
    category = get(h_category, 'Value');
    if category ~= 3
        return;
    end
    h_layer = findobj(h_adv, 'Tag', 'param2_layer');
    h_mattype = findobj(h_adv, 'Tag', 'param2_mattype');
    h_mattype_label = findobj(h_adv, 'Tag', 'param2_mattype_label');
    layer_idx = get(h_layer, 'Value');
    h_property = findobj(h_adv, 'Tag', 'param2_property');
    h_property_label = findobj(h_adv, 'Tag', 'param2_property_label');
    h_unit = findobj(h_adv, 'Tag', 'param2_unit');
    if isempty(layer_idx)
        return;
    end
    if layer_idx <= app_data.N_layers
        layer_data = app_data.layers{layer_idx};
        is_constant = strcmp(layer_data{14}, 'constant');
        set(h_mattype_label, 'Visible', 'on');
        set(h_mattype, 'Visible', 'on');
        if is_constant
            set(h_mattype, 'String', {'Постоянный'});
            set(h_mattype, 'Value', 1);
            mattype = 1;
            props = {'Re(ε)'; 'Im(ε)'; 'Re(μ)'; 'Im(μ)'};
            set(h_unit, 'String', '(безр.)');
        else
            set(h_mattype, 'String', {'Друде'; 'Лоренц'});
            has_drude = (layer_data{2} > 0) || (layer_data{3} > 0);
            has_lorentz = (layer_data{4} > 0) || (layer_data{5} > 0);
            if has_drude && ~has_lorentz
                set(h_mattype, 'Value', 1);
            elseif has_lorentz && ~has_drude
                set(h_mattype, 'Value', 2);
            else
                set(h_mattype, 'Value', 1);
            end
            mattype = get(h_mattype, 'Value');
            switch mattype
                case 1
                    props = {'ωₚ (ε)'; 'γ (ε)'; 'ωₚ (μ)'; 'γ (μ)'};
                    set(h_unit, 'String', '(рад/с)');
                case 2
                    props = {'f (ε)'; 'ω₀ (ε)'; 'Γ (ε)'; 'f (μ)'; 'ω₀ (μ)'; 'Γ (μ)'};
                    set(h_unit, 'String', '(разная)');
            end
        end
        set(h_property, 'String', props);
        set(h_property_label, 'Visible', 'on');
        set(h_property, 'Visible', 'on');
        set(h_property, 'Callback', {@update_unit_on_property_change, 2});
        set(findobj(h_adv, 'Tag', 'param2_range_label'), 'Visible', 'on');
        set(findobj(h_adv, 'Tag', 'param2_min'), 'Visible', 'on');
        set(findobj(h_adv, 'Tag', 'param2_from_label'), 'Visible', 'on');
        set(findobj(h_adv, 'Tag', 'param2_max'), 'Visible', 'on');
        set(findobj(h_adv, 'Tag', 'param2_to_label'), 'Visible', 'on');
        set(findobj(h_adv, 'Tag', 'param2_step'), 'Visible', 'on');
        set(findobj(h_adv, 'Tag', 'param2_step_label'), 'Visible', 'on');
        set(findobj(h_adv, 'Tag', 'param2_unit'), 'Visible', 'on');
    end
end

function update_param2_subcategory_callback(src, ~)
    h_adv = gcbf;
    app_data = get_app_data();
    category = get(src, 'Value');
    h_subcat = findobj(h_adv, 'Tag', 'param2_subcategory');
    h_subcat_label = findobj(h_adv, 'Tag', 'param2_subcat_label');
    h_layer = findobj(h_adv, 'Tag', 'param2_layer');
    h_layer_label = findobj(h_adv, 'Tag', 'param2_layer_label');
    h_property = findobj(h_adv, 'Tag', 'param2_property');
    h_property_label = findobj(h_adv, 'Tag', 'param2_property_label');
    h_mattype = findobj(h_adv, 'Tag', 'param2_mattype');
    h_mattype_label = findobj(h_adv, 'Tag', 'param2_mattype_label');
    h_unit = findobj(h_adv, 'Tag', 'param2_unit');
    set(h_layer_label, 'Visible', 'off');
    set(h_layer, 'Visible', 'off');
    set(h_property_label, 'Visible', 'off');
    set(h_property, 'Visible', 'off');
    set(h_mattype_label, 'Visible', 'off');
    set(h_mattype, 'Visible', 'off');
    set(h_subcat_label, 'Visible', 'off');
    set(h_subcat, 'Visible', 'off');
    set(findobj(h_adv, 'Tag', 'param2_range_label'), 'Visible', 'on');
    set(findobj(h_adv, 'Tag', 'param2_min'), 'Visible', 'on');
    set(findobj(h_adv, 'Tag', 'param2_from_label'), 'Visible', 'on');
    set(findobj(h_adv, 'Tag', 'param2_max'), 'Visible', 'on');
    set(findobj(h_adv, 'Tag', 'param2_to_label'), 'Visible', 'on');
    set(findobj(h_adv, 'Tag', 'param2_step'), 'Visible', 'on');
    set(findobj(h_adv, 'Tag', 'param2_step_label'), 'Visible', 'on');
    set(findobj(h_adv, 'Tag', 'param2_unit'), 'Visible', 'on');
    switch category
        case 1
            set(h_subcat_label, 'Visible', 'on');
            set(h_subcat, 'Visible', 'on');
            set(h_subcat, 'String', {'Длина волны'; 'Перетяжка w₀'; 'Угол падения'});
            set(h_subcat, 'Value', 1);
            update_param2_details_callback(h_subcat, []);
        case 2
            set(h_subcat_label, 'Visible', 'on');
            set(h_subcat, 'Visible', 'on');
            set(h_subcat, 'String', {'Толщина слоя'});
            set(h_subcat, 'Value', 1);
            set(h_layer_label, 'Visible', 'on');
            set(h_layer, 'Visible', 'on');
            set(h_unit, 'String', '(нм)');
            set(findobj(h_adv, 'Tag', 'param2_min'), 'String', '10');
            set(findobj(h_adv, 'Tag', 'param2_max'), 'String', '500');
            set(findobj(h_adv, 'Tag', 'param2_step'), 'String', '10');
        case 3
            set(h_subcat_label, 'Visible', 'on');
            set(h_subcat, 'Visible', 'on');
            set(h_subcat, 'String', {'Свойства материала'});
            set(h_subcat, 'Value', 1);
            set(h_layer_label, 'Visible', 'on');
            set(h_layer, 'Visible', 'on');
            set(h_mattype_label, 'Visible', 'on');
            set(h_mattype, 'Visible', 'on');
            update_param2_property_callback(h_layer, []);
    end
end

function update_unit_on_property_change(src, ~, param_num)
    h_adv = gcbf;
    property_idx = get(src, 'Value');
    if isempty(property_idx)
        return;
    end
    if param_num == 1
        unit_tag = 'param1_unit';
    else
        unit_tag = 'param2_unit';
    end
    h_unit = findobj(h_adv, 'Tag', unit_tag);
    if isequal(get(src, 'String'), {'f (ε)'; 'ω₀ (ε)'; 'Γ (ε)'; 'f (μ)'; 'ω₀ (μ)'; 'Γ (μ)'})
        switch property_idx
            case {1, 4}
                set(h_unit, 'String', '(безр.)');
            case {2, 3, 5, 6}
                set(h_unit, 'String', '(рад/с)');
        end
    elseif isequal(get(src, 'String'), {'ωₚ (ε)'; 'γ (ε)'; 'ωₚ (μ)'; 'γ (μ)'})
        set(h_unit, 'String', '(рад/с)');
    end
end

function update_param1_mattype_callback(src, ~)
    h_adv = gcbf;
    h_mattype = findobj(h_adv, 'Tag', 'param1_mattype');
    h_property = findobj(h_adv, 'Tag', 'param1_property');
    h_unit = findobj(h_adv, 'Tag', 'param1_unit');
    mattype = get(h_mattype, 'Value');
    switch mattype
        case 1
            props = {'ωₚ (ε)'; 'γ (ε)'; 'ωₚ (μ)'; 'γ (μ)'};
            set(h_unit, 'String', '(рад/с)');
        case 2
            props = {'f (ε)'; 'ω₀ (ε)'; 'Γ (ε)'; 'f (μ)'; 'ω₀ (μ)'; 'Γ (μ)'};
            set(h_unit, 'String', '(разная)');
    end
    set(h_property, 'String', props);
    set(h_property, 'Value', 1);
end

function update_param2_mattype_callback(src, ~)
    h_adv = gcbf;
    h_mattype = findobj(h_adv, 'Tag', 'param2_mattype');
    h_property = findobj(h_adv, 'Tag', 'param2_property');
    h_unit = findobj(h_adv, 'Tag', 'param2_unit');
    mattype = get(h_mattype, 'Value');
    switch mattype
        case 1
            props = {'ωₚ (ε)'; 'γ (ε)'; 'ωₚ (μ)'; 'γ (μ)'};
            set(h_unit, 'String', '(рад/с)');
        case 2
            props = {'f (ε)'; 'ω₀ (ε)'; 'Γ (ε)'; 'f (μ)'; 'ω₀ (μ)'; 'Γ (μ)'};
            set(h_unit, 'String', '(разная)');
    end
    set(h_property, 'String', props);
    set(h_property, 'Value', 1);
end

% ======================================================================
% ПОСТРОЕНИЕ ПРОДВИНУТЫХ ГРАФИКОВ (ИЗМЕНЁННАЯ ВЕРСИЯ)
% ======================================================================
function build_advanced_graphics_callback(src, ~)
    h_adv = gcbf;
    app_data = get_app_data();
    adv_status = findobj(h_adv, 'Tag', 'adv_status');
    if isempty(adv_status)
        adv_status = uicontrol('Parent', h_adv, ...
            'Style', 'text', 'String', 'Готов к построению', ...
            'Position', [20, 110, 710, 15], ...
            'FontSize', 9, 'HorizontalAlignment', 'center', ...
            'ForegroundColor', [0, 0.5, 0], 'Tag', 'adv_status');
    end
    set(adv_status, 'String', 'Выполняется расчет...', 'ForegroundColor', [1, 0.5, 0]);
    drawnow;
    
    try
        % === ИНИЦИАЛИЗАЦИЯ ПАРАЛЛЕЛЬНОГО ПУЛА ===
        init_parallel_pool();
        use_parfor = check_parfor_available();
        
        h_2d = findobj(h_adv, 'Tag', 'adv_graph_2d');
        h_3d = findobj(h_adv, 'Tag', 'adv_graph_3d');
        is_2d = get(h_2d, 'Value');
        is_3d = get(h_3d, 'Value');
        
        if ~is_2d && ~is_3d
            warndlg('Выберите хотя бы один тип графика (2D или 3D)!', 'Ошибка');
            set(adv_status, 'String', 'Ошибка: не выбран тип графика', 'ForegroundColor', [1, 0, 0]);
            return;
        end
        
        % === ПОЛУЧАЕМ КОЛИЧЕСТВО ТОЧЕК ПО УГЛУ ===
        n_angle_points = str2double(get(findobj(h_adv, 'Tag', 'adv_n_angle_points'), 'String'));
        if isempty(n_angle_points) || n_angle_points < 100
            n_angle_points = 1000;
        elseif n_angle_points > 50000
            n_angle_points = 50000;
        end
        
        if use_parfor
            fprintf('Точность расчёта: %d точек по углу (ПАРАЛЛЕЛЬНЫЙ режим)\n', n_angle_points);
        else
            fprintf('Точность расчёта: %d точек по углу (ПОСЛЕДОВАТЕЛЬНЫЙ режим)\n', n_angle_points);
        end
        
        % === ПОЛУЧАЕМ ВЫБРАННЫЕ ТИПЫ СДВИГОВ ===
        shift_types = [];
        if get(findobj(h_adv, 'Tag', 'adv_shift_gh_spatial'), 'Value')
            shift_types(end+1) = 1;  % Пространственный GH
        end
        if get(findobj(h_adv, 'Tag', 'adv_shift_if_spatial'), 'Value')
            shift_types(end+1) = 2;  % Пространственный IF
        end
        if get(findobj(h_adv, 'Tag', 'adv_shift_gh_angular'), 'Value')
            shift_types(end+1) = 3;  % Угловой GH
        end
        if get(findobj(h_adv, 'Tag', 'adv_shift_if_angular'), 'Value')
            shift_types(end+1) = 4;  % Угловой IF
        end
        
        if isempty(shift_types)
            warndlg('Выберите хотя бы один тип сдвига!', 'Ошибка');
            set(adv_status, 'String', 'Ошибка: не выбран тип сдвига', 'ForegroundColor', [1, 0, 0]);
            return;
        end
        
        param1 = get_parameter_settings(h_adv, 1, app_data);
        param2 = [];
        if is_3d
            param2 = get_parameter_settings(h_adv, 2, app_data);
            if isequal(param1.id, param2.id)
                warndlg('Для 3D графика выберите два РАЗНЫХ параметра!', 'Ошибка');
                set(adv_status, 'String', 'Ошибка: одинаковые параметры', 'ForegroundColor', [1, 0, 0]);
                return;
            end
        end
        
        lambda0 = str2double(get(findobj(h_adv, 'Tag', 'adv_lambda_edit'), 'String')) * 1e-9;
        w0 = str2double(get(findobj(h_adv, 'Tag', 'adv_w0_edit'), 'String')) * 1e-6;
        theta_fixed = deg2rad(str2double(get(findobj(h_adv, 'Tag', 'adv_theta_edit'), 'String')));
        
        pols = {};
        if get(findobj(h_adv, 'Tag', 'adv_pol_check'), 'Value'), pols{end+1} = 's'; end
        if get(findobj(h_adv, 'Tag', 'adv_pol_check2'), 'Value'), pols{end+1} = 'p'; end
        if get(findobj(h_adv, 'Tag', 'adv_pol_check3'), 'Value'), pols{end+1} = 'RCP'; end
        if get(findobj(h_adv, 'Tag', 'adv_pol_check4'), 'Value'), pols{end+1} = 'LCP'; end
        
        if isempty(pols)
            warndlg('Выберите хотя бы одну поляризацию!', 'Ошибка');
            return;
        end
        
        N_layers = app_data.N_layers;
        layers = struct();
        for i = 1:N_layers
            layer_data = app_data.layers{i};
            layers(i).eps_inf = layer_data{1};
            layers(i).eps_drude.omega_p = layer_data{2};
            layers(i).eps_drude.gamma = layer_data{3};
            if layer_data{4} > 0
                layers(i).eps_lorentz = struct('f', layer_data{4}, ...
                    'omega_0', layer_data{5}, 'Gamma', layer_data{6});
            else
                layers(i).eps_lorentz = [];
            end
            layers(i).mu_inf = layer_data{7};
            layers(i).mu_drude.omega_p = layer_data{8};
            layers(i).mu_drude.gamma = layer_data{9};
            if layer_data{10} > 0
                layers(i).mu_lorentz = struct('f', layer_data{10}, ...
                    'omega_0', layer_data{11}, 'Gamma', layer_data{12});
            else
                layers(i).mu_lorentz = [];
            end
            layers(i).d = layer_data{13};
            layers(i).type = layer_data{14};
        end
        
        % === СТРОИМ ГРАФИКИ ДЛЯ ВСЕХ ВЫБРАННЫХ ТИПОВ СДВИГОВ ===
        for s = 1:length(shift_types)
            shift_type = shift_types(s);
            fprintf('Построение графика для типа сдвига %d из %d...\n', s, length(shift_types));
            
            if is_2d
                build_2d_graphs(param1, lambda0, w0, theta_fixed, pols, shift_type, layers, app_data, n_angle_points);
            end
            if is_3d
                build_3d_graphs(param1, param2, lambda0, w0, theta_fixed, pols, shift_type, layers, app_data, n_angle_points);
            end
        end
        
        if use_parfor
            set(adv_status, 'String', sprintf('Графики построены (%d типов сдвига, параллельный расчёт)!', length(shift_types)), 'ForegroundColor', [0, 0.5, 0]);
        else
            set(adv_status, 'String', sprintf('Графики построены (%d типов сдвига)!', length(shift_types)), 'ForegroundColor', [0, 0.5, 0]);
        end
    catch ME
        warndlg(sprintf('Ошибка: %s', ME.message), 'Ошибка');
        set(adv_status, 'String', 'Ошибка построения', 'ForegroundColor', [1, 0, 0]);
    end
end

function param = get_parameter_settings(h_adv, param_num, app_data)
    param = struct();
    prefix = sprintf('param%d', param_num);
    param.category = get(findobj(h_adv, 'Tag', [prefix '_category']), 'Value');
    param.subcategory = get(findobj(h_adv, 'Tag', [prefix '_subcategory']), 'Value');
    if param.category == 1
        subcat_names = {'Длина волны', 'Перетяжка w₀', 'Угол падения'};
        param.id = sprintf('rad_%d', param.subcategory);
        param.name = subcat_names{param.subcategory};
        param.type = 'radiation';
        param.full_name = param.name;
        switch param.subcategory
            case 1, param.unit = 'нм';
            case 2, param.unit = 'мкм';
            case 3, param.unit = 'град';
        end
        param.mattype = [];
        param.property = [];
    elseif param.category == 2
        param.layer = get(findobj(h_adv, 'Tag', [prefix '_layer']), 'Value');
        param.id = sprintf('thick_%d', param.layer);
        param.name = sprintf('Толщина слоя %d', param.layer);
        param.full_name = param.name;
        param.type = 'thickness';
        param.unit = 'нм';
        param.mattype = [];
        param.property = [];
    elseif param.category == 3
        param.layer = get(findobj(h_adv, 'Tag', [prefix '_layer']), 'Value');
        h_mattype = findobj(h_adv, 'Tag', [prefix '_mattype']);
        if ~isempty(h_mattype)
            param.mattype = get(h_mattype, 'Value');
        else
            param.mattype = 1;
        end
        h_property = findobj(h_adv, 'Tag', [prefix '_property']);
        if ~isempty(h_property)
            param.property = get(h_property, 'Value');
        else
            param.property = 1;
        end
        mattype_strings = get(h_mattype, 'String');
        if iscell(mattype_strings)
            actual_mattype_name = mattype_strings{param.mattype};
        else
            actual_mattype_name = mattype_strings;
        end
        switch actual_mattype_name
            case 'Постоянный'
                prop_names = {'Re(ε)', 'Im(ε)', 'Re(μ)', 'Im(μ)'};
                unit = 'безр.';
                mattype_display = 'Постоянный';
            case 'Друде'
                prop_names = {'ωₚ(ε)', 'γ(ε)', 'ωₚ(μ)', 'γ(μ)'};
                unit = 'рад/с';
                mattype_display = 'Друде';
            case 'Лоренц'
                prop_names = {'f(ε)', 'ω₀(ε)', 'Γ(ε)', 'f(μ)', 'ω₀(μ)', 'Γ(μ)'};
                unit = 'разная';
                mattype_display = 'Лоренц';
            otherwise
                prop_names = {'Re(ε)', 'Im(ε)', 'Re(μ)', 'Im(μ)'};
                unit = 'безр.';
                mattype_display = 'Постоянный';
        end
        if param.property > length(prop_names)
            param.property = 1;
        end
        prop_name = prop_names{param.property};
        param.id = sprintf('prop_%d_%d_%d', param.layer, param.mattype, param.property);
        param.name = sprintf('Слой %d: %s', param.layer, prop_name);
        param.full_name = sprintf('Слой %d: %s (%s)', param.layer, prop_name, mattype_display);
        param.type = 'property';
        param.unit = unit;
    end
    param.min = str2double(get(findobj(h_adv, 'Tag', [prefix '_min']), 'String'));
    param.max = str2double(get(findobj(h_adv, 'Tag', [prefix '_max']), 'String'));
    param.step = str2double(get(findobj(h_adv, 'Tag', [prefix '_step']), 'String'));
    param.range = param.min:param.step:param.max;
    if isempty(param.range)
        param.range = linspace(param.min, param.max, 50);
    end
end

% ======================================================================
% 2D ГРАФИКИ (ИЗМЕНЁННАЯ ВЕРСИЯ С PARFOR)
% ======================================================================
function build_2d_graphs(param1, lambda0, w0, theta_fixed, pols, shift_type, layers, app_data, n_angle_points)
    N_points = length(param1.range);
    N_pols = length(pols);
    results = zeros(N_pols, N_points);
    base_layers = layers;
    
    % === ИНИЦИАЛИЗАЦИЯ ПАРАЛЛЕЛЬНОГО ПУЛА ===
    init_parallel_pool();
    use_parfor = check_parfor_available();
    
    param_values = param1.range;
    
    if use_parfor
        % === ПАРАЛЛЕЛЬНЫЙ ЦИКЛ ===
        parfor i = 1:N_points
            curr_lambda = lambda0;
            curr_w0 = w0;
            curr_theta = theta_fixed;
            
            if strcmp(param1.type, 'radiation')
                switch param1.subcategory
                    case 1, curr_lambda = param_values(i) * 1e-9;
                    case 2, curr_w0 = param_values(i) * 1e-6;
                    case 3, curr_theta = deg2rad(param_values(i));
                end
                curr_layers = base_layers;
            elseif strcmp(param1.type, 'thickness')
                curr_layers = modify_structure(base_layers, param1, param_values(i), app_data, 1);
            elseif strcmp(param1.type, 'property')
                curr_layers = modify_structure(base_layers, param1, param_values(i), app_data, 1);
            else
                curr_layers = base_layers;
            end
            
            % === РАСЧЁТ ВСЕХ СДВИГОВ ОДНОВРЕМЕННО ===
            shifts = calculate_shifts_at_point(curr_layers, curr_lambda, curr_w0, curr_theta, n_angle_points);
            
            % === СОХРАНЕНИЕ РЕЗУЛЬТАТОВ ДЛЯ ВСЕХ ПОЛЯРИЗАЦИЙ ===
            for j = 1:N_pols
                shift_value = get_shift_value(shifts, pols{j}, shift_type);
                if ~isfinite(shift_value)
                    shift_value = 0;
                end
                            % Нормируем пространственные сдвиги на длину волны (тип 1 и 2)
            if shift_type == 1 || shift_type == 2
                results(j, i) = double(shift_value) / lambda0;
            else
                results(j, i) = double(shift_value);
            end
            end
        end
    else
        % === ПОСЛЕДОВАТЕЛЬНЫЙ ЦИКЛ ===
        for i = 1:N_points
            curr_lambda = lambda0;
            curr_w0 = w0;
            curr_theta = theta_fixed;
            
            if strcmp(param1.type, 'radiation')
                switch param1.subcategory
                    case 1, curr_lambda = param_values(i) * 1e-9;
                    case 2, curr_w0 = param_values(i) * 1e-6;
                    case 3, curr_theta = deg2rad(param_values(i));
                end
                curr_layers = base_layers;
            elseif strcmp(param1.type, 'thickness')
                curr_layers = modify_structure(base_layers, param1, param_values(i), app_data, 1);
            elseif strcmp(param1.type, 'property')
                curr_layers = modify_structure(base_layers, param1, param_values(i), app_data, 1);
            else
                curr_layers = base_layers;
            end
            
            shifts = calculate_shifts_at_point(curr_layers, curr_lambda, curr_w0, curr_theta, n_angle_points);
            
            for j = 1:N_pols
                shift_value = get_shift_value(shifts, pols{j}, shift_type);
                if ~isfinite(shift_value)
                    shift_value = 0;
                end
                            % Нормируем пространственные сдвиги на длину волны (тип 1 и 2)
            if shift_type == 1 || shift_type == 2
                results(j, i) = double(shift_value) / lambda0;
            else
                results(j, i) = double(shift_value);
            end
            end
        end
    end
    
    % === ПОСТРОЕНИЕ ГРАФИКА ===
    shift_names = {'Пространственный GH', 'Пространственный IF', 'Угловой GH', 'Угловой IF'};
    figure('Name', sprintf('2D: %s (%s)', param1.full_name, shift_names{shift_type}), ...
        'Position', [100, 100, 1200, 700], 'Color', 'w');
    colors = lines(N_pols);
    hold on;
    for j = 1:N_pols
        plot(param1.range, results(j, :), 'Color', colors(j,:), 'LineWidth', 2, ...
            'DisplayName', sprintf('%s поляризация', pols{j}));
    end
    hold off;
    grid on;
    xlabel(sprintf('%s (%s)', param1.full_name, param1.unit), 'FontSize', 12);
    ylabel(get_shift_label(shift_type), 'FontSize', 12);
    title(sprintf('Зависимость %s от: %s', shift_names{shift_type}, param1.full_name), 'FontSize', 14, 'FontWeight', 'bold');
    legend('Location', 'best');
    
    if use_parfor
        fprintf('2D график построен (параллельный режим, %d точек, тип сдвига %d)\n', N_points, shift_type);
    else
        fprintf('2D график построен (последовательный режим, %d точек, тип сдвига %d)\n', N_points, shift_type);
    end
end

% ======================================================================
% 3D ГРАФИКИ (ИЗМЕНЁННАЯ ВЕРСИЯ С PARFOR)
% ======================================================================
function build_3d_graphs(param1, param2, lambda0, w0, theta_fixed, pols, shift_type, layers, app_data, n_angle_points)
    N_x = length(param1.range);
    N_y = length(param2.range);
    [X, Y] = meshgrid(param1.range, param2.range);
    base_layers = layers;
    
    % === ИНИЦИАЛИЗАЦИЯ ПАРАЛЛЕЛЬНОГО ПУЛА ===
    init_parallel_pool();
    use_parfor = check_parfor_available();
    
    shift_names = {'Пространственный GH', 'Пространственный IF', 'Угловой GH', 'Угловой IF'};
    
    for k = 1:length(pols)
        Z = zeros(N_y, N_x);
        
        if use_parfor
            % === ПАРАЛЛЕЛЬНЫЙ ЦИКЛ ПО ТОЧКАМ СЕТКИ ===
            parfor i = 1:N_x
                for j = 1:N_y
                    curr_lambda = lambda0;
                    curr_w0 = w0;
                    curr_theta = theta_fixed;
                    curr_layers = base_layers;
                    
                    if strcmp(param1.type, 'radiation')
                        switch param1.subcategory
                            case 1, curr_lambda = param1.range(i) * 1e-9;
                            case 2, curr_w0 = param1.range(i) * 1e-6;
                            case 3, curr_theta = deg2rad(param1.range(i));
                        end
                    elseif strcmp(param1.type, 'thickness')
                        curr_layers = modify_structure(curr_layers, param1, param1.range(i), app_data, 1);
                    elseif strcmp(param1.type, 'property')
                        curr_layers = modify_structure(curr_layers, param1, param1.range(i), app_data, 1);
                    end
                    
                    if strcmp(param2.type, 'radiation')
                        switch param2.subcategory
                            case 1, curr_lambda = param2.range(j) * 1e-9;
                            case 2, curr_w0 = param2.range(j) * 1e-6;
                            case 3, curr_theta = deg2rad(param2.range(j));
                        end
                    elseif strcmp(param2.type, 'thickness')
                        curr_layers = modify_structure(curr_layers, param2, param2.range(j), app_data, 2);
                    elseif strcmp(param2.type, 'property')
                        curr_layers = modify_structure(curr_layers, param2, param2.range(j), app_data, 2);
                    end
                    
                    shifts = calculate_shifts_at_point(curr_layers, curr_lambda, curr_w0, curr_theta, n_angle_points);
                              shift_val = get_shift_value(shifts, pols{k}, shift_type);
           % Нормировка пространственных сдвигов на длину волны (в метрах)
           if shift_type == 1 || shift_type == 2
               Z(j, i) = shift_val / lambda0;
           else
               Z(j, i) = shift_val;
           end
                end
            end
        else
            % === ПОСЛЕДОВАТЕЛЬНЫЙ ЦИКЛ ===
            for i = 1:N_x
                for j = 1:N_y
                    curr_lambda = lambda0;
                    curr_w0 = w0;
                    curr_theta = theta_fixed;
                    curr_layers = base_layers;
                    
                    if strcmp(param1.type, 'radiation')
                        switch param1.subcategory
                            case 1, curr_lambda = param1.range(i) * 1e-9;
                            case 2, curr_w0 = param1.range(i) * 1e-6;
                            case 3, curr_theta = deg2rad(param1.range(i));
                        end
                    elseif strcmp(param1.type, 'thickness')
                        curr_layers = modify_structure(curr_layers, param1, param1.range(i), app_data, 1);
                    elseif strcmp(param1.type, 'property')
                        curr_layers = modify_structure(curr_layers, param1, param1.range(i), app_data, 1);
                    end
                    
                    if strcmp(param2.type, 'radiation')
                        switch param2.subcategory
                            case 1, curr_lambda = param2.range(j) * 1e-9;
                            case 2, curr_w0 = param2.range(j) * 1e-6;
                            case 3, curr_theta = deg2rad(param2.range(j));
                        end
                    elseif strcmp(param2.type, 'thickness')
                        curr_layers = modify_structure(curr_layers, param2, param2.range(j), app_data, 2);
                    elseif strcmp(param2.type, 'property')
                        curr_layers = modify_structure(curr_layers, param2, param2.range(j), app_data, 2);
                    end
                    
                    shifts = calculate_shifts_at_point(curr_layers, curr_lambda, curr_w0, curr_theta, n_angle_points);
                               shift_val = get_shift_value(shifts, pols{k}, shift_type);
           % Нормировка пространственных сдвигов на длину волны (в метрах)
           if shift_type == 1 || shift_type == 2
               Z(j, i) = shift_val / lambda0;
           else
               Z(j, i) = shift_val;
           end
                end
            end
        end
        
        % === ПОСТРОЕНИЕ ГРАФИКОВ ===
        figure('Name', sprintf('3D: %s vs %s (%s)', param1.full_name, param2.full_name, shift_names{shift_type}), ...
            'Position', [50, 50, 1600, 900], 'Color', 'w');
        subplot(1, 2, 1);
        surf(X, Y, Z, 'EdgeColor', 'none');
        colormap jet;
        cb = colorbar;
        cb.Label.String = get_shift_label(shift_type);
        xlabel(sprintf('%s (%s)', param1.full_name, param1.unit));
        ylabel(sprintf('%s (%s)', param2.full_name, param2.unit));
        title(sprintf('3D поверхность (%s, %s)', pols{k}, shift_names{shift_type}));
        view(45, 30);
        axis tight;
        subplot(1, 2, 2);
        contourf(X, Y, Z, 40);
        cb = colorbar;
        cb.Label.String = get_shift_label(shift_type);
        xlabel(sprintf('%s (%s)', param1.full_name, param1.unit));
        ylabel(sprintf('%s (%s)', param2.full_name, param2.unit));
        title(sprintf('Контурный график (%s, %s)', pols{k}, shift_names{shift_type}));
        axis equal;
        axis tight;
    end
    
    if use_parfor
        fprintf('3D график построен (параллельный режим, тип сдвига %d)\n', shift_type);
    else
        fprintf('3D график построен (последовательный режим, тип сдвига %d)\n', shift_type);
    end
end

% ======================================================================
% МОДИФИКАЦИЯ СТРУКТУРЫ СЛОЁВ
% ======================================================================
function layers = modify_structure(layers, param, value, app_data, param_num)
    if ~isfield(param, 'type')
        return;
    end
    switch param.type
        case 'thickness'
            if isfield(param, 'layer') && ~isempty(param.layer)
                if param.layer <= length(layers)
                    layers(param.layer).d = double(value) * 1e-9;
                end
            end
        case 'property'
            if ~isfield(param, 'layer') || isempty(param.layer)
                return;
            end
            if ~isfield(param, 'mattype') || isempty(param.mattype)
                return;
            end
            if ~isfield(param, 'property') || isempty(param.property)
                return;
            end
            layer_idx = param.layer;
            value = double(value);
            prefix = sprintf('param%d', param_num);
            h_adv = findall(0, 'Name', 'Продвинутые графики - Настройка');
            actual_type = 'Постоянный';
            if ~isempty(h_adv)
                h_mattype = findobj(h_adv(1), 'Tag', [prefix '_mattype']);
                if ~isempty(h_mattype)
                    mattype_strings = get(h_mattype, 'String');
                    if iscell(mattype_strings) && param.mattype <= length(mattype_strings)
                        actual_type = mattype_strings{param.mattype};
                    end
                end
            end
            if layer_idx <= length(layers)
                switch actual_type
                    case 'Друде'
                        if ~isfield(layers(layer_idx), 'eps_drude')
                            layers(layer_idx).eps_drude = struct('omega_p', 0, 'gamma', 0);
                        end
                        if ~isfield(layers(layer_idx), 'mu_drude')
                            layers(layer_idx).mu_drude = struct('omega_p', 0, 'gamma', 0);
                        end
                        switch param.property
                            case 1, layers(layer_idx).eps_drude.omega_p = value;
                            case 2, layers(layer_idx).eps_drude.gamma = value;
                            case 3, layers(layer_idx).mu_drude.omega_p = value;
                            case 4, layers(layer_idx).mu_drude.gamma = value;
                        end
                    case 'Лоренц'
                        if ~isfield(layers(layer_idx), 'eps_lorentz')
                            layers(layer_idx).eps_lorentz = struct('f', 0, 'omega_0', 0, 'Gamma', 0);
                        end
                        if ~isfield(layers(layer_idx), 'mu_lorentz')
                            layers(layer_idx).mu_lorentz = struct('f', 0, 'omega_0', 0, 'Gamma', 0);
                        end
                        switch param.property
                            case 1, layers(layer_idx).eps_lorentz.f = value;
                            case 2, layers(layer_idx).eps_lorentz.omega_0 = value;
                            case 3, layers(layer_idx).eps_lorentz.Gamma = value;
                            case 4, layers(layer_idx).mu_lorentz.f = value;
                            case 5, layers(layer_idx).mu_lorentz.omega_0 = value;
                            case 6, layers(layer_idx).mu_lorentz.Gamma = value;
                        end
                    otherwise
                        switch param.property
                            case 1
                                old_im = imag(layers(layer_idx).eps_inf);
                                layers(layer_idx).eps_inf = value + 1i*old_im;
                            case 2
                                old_re = real(layers(layer_idx).eps_inf);
                                layers(layer_idx).eps_inf = old_re + 1i*value;
                            case 3
                                old_im = imag(layers(layer_idx).mu_inf);
                                layers(layer_idx).mu_inf = value + 1i*old_im;
                            case 4
                                old_re = real(layers(layer_idx).mu_inf);
                                layers(layer_idx).mu_inf = old_re + 1i*value;
                        end
                end
            end
    end
end

% ======================================================================
% === ОПТИМИЗИРОВАННАЯ ФУНКЦИЯ РАСЧЁТА ВСЕХ СДВИГОВ ОДНОВРЕМЕННО ===
% === Версия 2.0: С корректным взвешиванием по интенсивности ===
% ======================================================================
function shifts = calculate_shifts_at_point(layers, lambda0, w0, theta, n_angle_points)
    % Обработка параметра точности
    if nargin < 5, n_angle_points = 5000; end
    if isempty(n_angle_points) || n_angle_points < 100, n_angle_points = 1000; end
    if n_angle_points > 50000, n_angle_points = 50000; end
    
    shifts = create_zero_shifts();
    
    try
        freq0 = 299792458 / lambda0;
        omega0 = 2 * pi * freq0;
        k0 = 2 * pi / lambda0;
        N_layers = length(layers);
        
        % ==================================================================
        % 1. ДИСПЕРСИЯ (векторизовано)
        % ==================================================================
        for i = 1:N_layers
            [eps_i, mu_i] = drude_lorentz_model(omega0, layers(i));
            layers(i).epsilon = eps_i;
            layers(i).mu = mu_i;
        end
        
        % ==================================================================
        % 2. СЕТКА УГЛОВ ДЛЯ ГРАДИЕНТА
        % ==================================================================
        theta_range_deg = linspace(0.01, 89.99, n_angle_points);
        theta_range = deg2rad(theta_range_deg);
        dtheta_range = theta_range(2) - theta_range(1);
        
        % ==================================================================
        % 3. ВОЛНОВЫЕ ВЕКТОРЫ (векторизовано)
        % ==================================================================
        kz = zeros(N_layers, length(theta_range));
        n = zeros(N_layers, 1);
        for i = 1:N_layers
            n(i) = sqrt(layers(i).epsilon * layers(i).mu);
            kx = k0 * n(1) * sin(theta_range);
            kz_sq = (k0^2 * layers(i).epsilon * layers(i).mu) - kx.^2;
            kz(i, :) = sqrt(kz_sq);
            % Выбор знака корня: затухание вглубь среды
            kz(i, imag(kz(i,:)) < 0) = -kz(i, imag(kz(i,:)) < 0);
        end
        
        % ==================================================================
        % 4. TMM ДЛЯ ВСЕХ УГЛОВ СРАЗУ (векторизовано)
        % ==================================================================
        R_s_all = zeros(1, length(theta_range));
        R_p_all = zeros(1, length(theta_range));
        for idx = 1:length(theta_range)
            % S-поляризация
            Y_s = kz(:,idx) ./ [layers.mu]';
            M_s = eye(2);
            for i = 1:N_layers-1
                gamma_s = Y_s(i) / Y_s(i+1);
                D_s = 0.5 * [1 + gamma_s, 1 - gamma_s; 1 - gamma_s, 1 + gamma_s];
                if isfinite(layers(i+1).d)
                    phi = kz(i+1,idx) * layers(i+1).d;
                    P_s = [exp(-1i*phi), 0; 0, exp(1i*phi)];
                    M_s = M_s * D_s * P_s;
                else
                    M_s = M_s * D_s;
                end
            end
            R_s_all(idx) = M_s(2,1) / M_s(1,1);
            
            % P-поляризация
            Y_p = kz(:,idx) ./ [layers.epsilon]';
            M_p = eye(2);
            for i = 1:N_layers-1
                gamma_p = Y_p(i) / Y_p(i+1);
                D_p = 0.5 * [1 + gamma_p, 1 - gamma_p; 1 - gamma_p, 1 + gamma_p];
                if isfinite(layers(i+1).d)
                    phi = kz(i+1,idx) * layers(i+1).d;
                    P_p = [exp(-1i*phi), 0; 0, exp(1i*phi)];
                    M_p = M_p * D_p * P_p;
                else
                    M_p = M_p * D_p;
                end
            end
            R_p_all(idx) = M_p(2,1) / M_p(1,1);
        end
        
        % ==================================================================
        % 5. ИНТЕНСИВНОСТИ И ВЕСА
        % ==================================================================
        Int_s = abs(R_s_all).^2;
        Int_p = abs(R_p_all).^2;
        Total_Int = Int_s + Int_p;
        
        % Нормированные веса (доля энергии в каждой поляризации)
        W_s = Int_s ./ (Total_Int + eps);
        W_p = Int_p ./ (Total_Int + eps);
        
        % Параметр Стокса S3 (степень циркулярности отражённого пучка)
        % Для входной циркулярной поляризации
        S3 = (Int_p - Int_s) ./ (Total_Int + eps);
        
        % ==================================================================
        % 6. ФАЗЫ И ГРАДИЕНТЫ
        % ==================================================================
        Phi_s = unwrap(angle(R_s_all));
        Phi_p = unwrap(angle(R_p_all));
        
        dPhi_s = gradient(Phi_s, dtheta_range);
        dPhi_p = gradient(Phi_p, dtheta_range);
        dDelta_Phi = gradient(Phi_p - Phi_s, dtheta_range);
        
        % Градиенты логарифмов амплитуд (для угловых сдвигов)
        Amp_s = abs(R_s_all);
        Amp_p = abs(R_p_all);
        dlnAmp_s = gradient(log(Amp_s + eps), dtheta_range);
        dlnAmp_p = gradient(log(Amp_p + eps), dtheta_range);
        dAmp_diff = gradient(Amp_p - Amp_s, dtheta_range);
        
        % ==================================================================
        % 7. МНОЖИТЕЛИ
        % ==================================================================
        n1 = n(1);
        cos_theta = cos(theta);
        sin_theta = sin(theta);
        cos_theta_safe = cos_theta;
        cos_theta_safe(abs(cos_theta_safe) < 1e-6) = 1e-6;
        sin_theta_safe = sin_theta;
        sin_theta_safe(abs(sin_theta_safe) < 1e-10) = 1e-10;
        
        factor_spatial = -1 / (k0 * n1 * cos_theta_safe);
        factor_angular = 1 / (k0^2 * n1^2 * w0^2 * cos_theta_safe);
        cot_theta = cos_theta ./ sin_theta_safe;
        
        % ==================================================================
        % 8. ИНТЕРПОЛЯЦИЯ ДЛЯ НУЖНОГО УГЛА (с экстраполяцией)
        % ==================================================================
        theta_deg_target = rad2deg(theta);
        
        dPhi_s_fixed = interp1(theta_range_deg, dPhi_s, theta_deg_target, 'linear', 'extrap');
        dPhi_p_fixed = interp1(theta_range_deg, dPhi_p, theta_deg_target, 'linear', 'extrap');
        dDelta_Phi_fixed = interp1(theta_range_deg, dDelta_Phi, theta_deg_target, 'linear', 'extrap');
        
        dlnAmp_s_fixed = interp1(theta_range_deg, dlnAmp_s, theta_deg_target, 'linear', 'extrap');
        dlnAmp_p_fixed = interp1(theta_range_deg, dlnAmp_p, theta_deg_target, 'linear', 'extrap');
        dAmp_diff_fixed = interp1(theta_range_deg, dAmp_diff, theta_deg_target, 'linear', 'extrap');
        
        W_s_fixed = interp1(theta_range_deg, W_s, theta_deg_target, 'linear', 'extrap');
        W_p_fixed = interp1(theta_range_deg, W_p, theta_deg_target, 'linear', 'extrap');
        S3_fixed = interp1(theta_range_deg, S3, theta_deg_target, 'linear', 'extrap');
        
        % ==================================================================
        % 9. СДВИГИ ДЛЯ S И P ПОЛЯРИЗАЦИЙ (базовые)
        % ==================================================================
        shifts.GH_s_spatial = factor_spatial * dPhi_s_fixed;
        shifts.GH_p_spatial = factor_spatial * dPhi_p_fixed;
        shifts.GH_s_angular = factor_angular * dlnAmp_s_fixed;
        shifts.GH_p_angular = factor_angular * dlnAmp_p_fixed;
        
        % Для линейных поляризаций IF сдвиг = 0 (в изотропных средах)
        shifts.IF_s_spatial = 0;
        shifts.IF_p_spatial = 0;
        shifts.IF_s_angular = 0;
        shifts.IF_p_angular = 0;
        
        % ==================================================================
        % 10. СДВИГИ ДЛЯ ЦИРКУЛЯРНЫХ ПОЛЯРИЗАЦИЙ (ВЗВЕШЕННЫЕ)
        % ==================================================================
        % GH сдвиги: взвешенное среднее по интенсивности S и P компонент
        % Это физически корректный центр тяжести полного пучка
        shifts.GH_rcp_spatial = W_s_fixed * shifts.GH_s_spatial + W_p_fixed * shifts.GH_p_spatial;
        shifts.GH_lcp_spatial = W_s_fixed * shifts.GH_s_spatial + W_p_fixed * shifts.GH_p_spatial;
        
        shifts.GH_rcp_angular = W_s_fixed * shifts.GH_s_angular + W_p_fixed * shifts.GH_p_angular;
        shifts.GH_lcp_angular = W_s_fixed * shifts.GH_s_angular + W_p_fixed * shifts.GH_p_angular;
        
        % IF сдвиги: включают параметр Стокса S3 для учёта эллиптичности
        % sigma = +1 для RCP, sigma = -1 для LCP
        IF_base_spatial = (cot_theta / (k0 * n1)) * dDelta_Phi_fixed;
        IF_base_angular = factor_angular * cot_theta * dAmp_diff_fixed;
        
        shifts.IF_rcp_spatial = -IF_base_spatial * S3_fixed;  % sigma = +1
        shifts.IF_lcp_spatial = +IF_base_spatial * S3_fixed;  % sigma = -1
        shifts.IF_rcp_angular = IF_base_angular * S3_fixed;   % sigma = +1
        shifts.IF_lcp_angular = -IF_base_angular * S3_fixed;  % sigma = -1
        
        % ==================================================================
        % 11. ОБРАБОТКА ГРАНИЧНЫХ СЛУЧАЕВ
        % ==================================================================
        % При нормальном падении (theta = 0) IF сдвиги отсутствуют
        if abs(sin_theta) < 1e-10
            shifts.IF_rcp_spatial = 0;
            shifts.IF_lcp_spatial = 0;
            shifts.IF_rcp_angular = 0;
            shifts.IF_lcp_angular = 0;
        end
        
        % При скользящем падении (theta -> 90°) cot_theta -> 0
        if abs(cos_theta) < 1e-10
            shifts.IF_rcp_spatial = 0;
            shifts.IF_lcp_spatial = 0;
            shifts.IF_rcp_angular = 0;
            shifts.IF_lcp_angular = 0;
        end
        
    catch ME
        fprintf('WARNING в calculate_shifts_at_point: %s\n', ME.message);
        shifts = create_zero_shifts();
    end
end

% ======================================================================
% === ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ: ИНИЦИАЛИЗАЦИЯ СТРУКТУРЫ СДВИГОВ ===
% ======================================================================
function shifts = create_zero_shifts()
    shifts.GH_s_spatial = 0;
    shifts.GH_p_spatial = 0;
    shifts.GH_rcp_spatial = 0;
    shifts.GH_lcp_spatial = 0;
    
    shifts.GH_s_angular = 0;
    shifts.GH_p_angular = 0;
    shifts.GH_rcp_angular = 0;
    shifts.GH_lcp_angular = 0;
    
    shifts.IF_s_spatial = 0;
    shifts.IF_p_spatial = 0;
    shifts.IF_rcp_spatial = 0;
    shifts.IF_lcp_spatial = 0;
    
    shifts.IF_s_angular = 0;
    shifts.IF_p_angular = 0;
    shifts.IF_rcp_angular = 0;
    shifts.IF_lcp_angular = 0;
end

function app_data = get_app_data()
    try
        app_data = evalin('base', 'gh_if_app_data');
    catch
        app_data = struct();
        app_data.lambda0 = 632.8;
        app_data.w0 = 20;
        app_data.N_layers = 4;
        app_data.n_angle_points = 5000;
        app_data.layers = cell(10, 1);
        for i = 1:10
            app_data.layers{i} = {1.0, 0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 0, 100e-9, 'constant'};
        end
        assignin('base', 'gh_if_app_data', app_data);
    end
end

function label = get_shift_label(shift_type)
    switch shift_type
        case 1, label = 'Пространственный сдвиг GH (\lambda_0)';
        case 2, label = 'Пространственный сдвиг IF (\lambda_0)';
        case 3, label = 'Угловой сдвиг GH (мкрад)';
        case 4, label = 'Угловой сдвиг IF (мкрад)';
        otherwise, label = 'Сдвиг';
    end
end

function value = get_shift_value(shifts, pol, shift_type)
    switch pol
        case 's'
            if shift_type == 1, value = shifts.GH_s_spatial;
            elseif shift_type == 2, value = 0;
            elseif shift_type == 3, value = shifts.GH_s_angular * 1e6;
            else, value = 0;
            end
        case 'p'
            if shift_type == 1, value = shifts.GH_p_spatial;
            elseif shift_type == 2, value = 0;
            elseif shift_type == 3, value = shifts.GH_p_angular * 1e6;
            else, value = 0;
            end
        case 'RCP'
            if shift_type == 1
                % === ИСПРАВЛЕНО: Прямое значение, а не среднее ===
                value = shifts.GH_rcp_spatial; 
            elseif shift_type == 2, value = shifts.IF_rcp_spatial;
            elseif shift_type == 3, value = shifts.GH_rcp_angular * 1e6;
            else, value = shifts.IF_rcp_angular * 1e6;
            end
        case 'LCP'
            if shift_type == 1
                % === ИСПРАВЛЕНО: Прямое значение, а не среднее ===
                value = shifts.GH_lcp_spatial;
            elseif shift_type == 2, value = shifts.IF_lcp_spatial;
            elseif shift_type == 3, value = shifts.GH_lcp_angular * 1e6;
            else, value = shifts.IF_lcp_angular * 1e6;
            end
    end
end

% ======================================================================
% ИНИЦИАЛИЗАЦИЯ ПАРАЛЛЕЛЬНОГО ПУЛА (ИСПРАВЛЕННАЯ ВЕРСИЯ)
% ======================================================================
function init_parallel_pool()
    persistent pool_initialized
    if isempty(pool_initialized)
        pool_initialized = false;
    end
    
    if ~pool_initialized
        try
            pool = gcp('nocreate');  % Проверяем существующий пул
            if isempty(pool)
                parpool('local');  % Создаём новый если нет
            end
            pool_initialized = true;
            fprintf('Параллельный пул инициализирован\n');
        catch ME
            warning('Не удалось инициализировать параллельный пул: %s. Будет использоваться последовательный расчёт.', ME.message);
            pool_initialized = false;
        end
    end
end

% ======================================================================
% ПРОВЕРКА ДОСТУПНОСТИ PARFOR
% ======================================================================
function use_parfor = check_parfor_available()
    try
        pool = gcp('nocreate');
        use_parfor = ~isempty(pool);
    catch
        use_parfor = false;
    end
end