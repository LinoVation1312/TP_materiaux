function AcoustiqueGUI_Complete_Bois()
    % ACOUSTIQUEGUI_COMPLETE_BOIS
    % - Ajout du Bois Lamellé Collé
    % - Slider ajusté pour atteindre 21mm+
    clc; close all;
    
    %% 1. Initialisation
    % Vecteur fréquence
    f = 10:5:25000; 
    omega = 2 * pi * f;
    c_air = 343;        
    rho_air = 1.2;      
    Z_air = rho_air * c_air; 
    
    % --- DEFINITION DES MATERIAUX ---
    % 1. Acier
    mat(1).nom = 'Acier';     
    mat(1).E = 210e9; mat(1).rho = 7800; mat(1).nu = 0.3;  mat(1).col = 'b';
    
    % 2. Aluminium
    mat(2).nom = 'Aluminium'; 
    mat(2).E = 70e9;  mat(2).rho = 2700; mat(2).nu = 0.33; mat(2).col = 'r';
    
    % 3. Inox
    mat(3).nom = 'Inox';      
    mat(3).E = 193e9; mat(3).rho = 7930; mat(3).nu = 0.3;  mat(3).col = 'g';
    
    % 4. Bois Lamellé Collé (Nouvel ajout)
    % E ~ 11 GPa (Moyenne résineux structuraux), Rho ~ 480 kg/m3
    mat(4).nom = 'Bois LC';   
    mat(4).E = 11e9;  mat(4).rho = 480;  mat(4).nu = 0.3;  mat(4).col = [0.6 0.4 0.2]; % Marron

    %% 2. Interface Graphique
    fig = figure('Name', 'Simulateur Acoustique - Avec Bois LC', ...
                 'NumberTitle', 'off', 'Color', 'w', 'Position', [100, 100, 1200, 700]);

    % --- Panneau de Contrôle ---
    pnl = uipanel(fig, 'Title', 'Paramètres', 'Position', [0.01 0.82 0.98 0.17], ...
                  'BackgroundColor', 'w', 'FontSize', 10);

    % A. SLIDER EPAISSEUR (Modifié pour permettre 21mm)
    uicontrol(pnl, 'Style', 'text', 'String', 'Épaisseur h :', ...
              'Position', [10 75 80 20], 'BackgroundColor', 'w', 'HorizontalAlignment', 'right');
    
    % Note: Max passé à 40mm, Valeur par défaut à 21mm pour votre cas
    h_slider = uicontrol(pnl, 'Style', 'slider', 'Min', 0.5, 'Max', 40, 'Value', 21, ...
                         'Position', [100 78 250 15], 'Callback', @updateAll); 
                     
    lbl_h = uicontrol(pnl, 'Style', 'text', 'String', '21.0 mm', ...
                      'Position', [360 75 60 20], 'BackgroundColor', 'w', 'FontWeight', 'bold');

    % B. SLIDERS FREQUENCE (Min et Max)
    % Freq Min
    uicontrol(pnl, 'Style', 'text', 'String', 'Freq Min :', ...
              'Position', [10 45 80 20], 'BackgroundColor', 'w', 'HorizontalAlignment', 'right');
    sl_fmin = uicontrol(pnl, 'Style', 'slider', 'Min', 10, 'Max', 5000, 'Value', 100, ...
                        'Position', [100 48 250 15], 'Callback', @updateAll);
    lbl_fmin = uicontrol(pnl, 'Style', 'text', 'String', '100 Hz', ...
                         'Position', [360 45 60 20], 'BackgroundColor', 'w');

    % Freq Max
    uicontrol(pnl, 'Style', 'text', 'String', 'Freq Max :', ...
              'Position', [10 15 80 20], 'BackgroundColor', 'w', 'HorizontalAlignment', 'right');
    sl_fmax = uicontrol(pnl, 'Style', 'slider', 'Min', 5000, 'Max', 25000, 'Value', 10000, ...
                        'Position', [100 18 250 15], 'Callback', @updateAll);
    lbl_fmax = uicontrol(pnl, 'Style', 'text', 'String', '10000 Hz', ...
                         'Position', [360 15 60 20], 'BackgroundColor', 'w');

    % C. CHECKBOX LOG X
    chk_log = uicontrol(pnl, 'Style', 'checkbox', 'String', 'Axe X Logarithmique', ...
                        'Position', [450 75 150 20], 'BackgroundColor', 'w', 'Value', 1, ... % Activé par défaut
                        'Callback', @updateAll);

    % D. Zone Info
    lbl_info = uicontrol(pnl, 'Style', 'text', 'String', '', ...
                         'Position', [600 10 500 80], 'BackgroundColor', 'w', ...
                         'HorizontalAlignment', 'left', 'FontSize', 9);

    % --- Axes ---
    axDisp = axes(fig, 'Position', [0.06 0.08 0.40 0.70]);
    hold(axDisp, 'on'); grid(axDisp, 'on'); box(axDisp, 'on');
    title(axDisp, 'Diagramme de Dispersion (k)'); ylabel(axDisp, 'k (rad/m)');

    axTL = axes(fig, 'Position', [0.55 0.08 0.40 0.70]);
    hold(axTL, 'on'); grid(axTL, 'on'); box(axTL, 'on');
    title(axTL, 'Loi de Masse'); ylabel(axTL, 'R (dB)');

    %% 3. Initialisation des Objets Graphiques
    % Ligne fixe (Air)
    plot(axDisp, f, omega/c_air, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Air (Son)');
    
    handlesMat = struct([]);
    for i = 1:length(mat)
        % Objets Dispersion
        handlesMat(i).hLineDisp = plot(axDisp, nan, nan, 'Color', mat(i).col, ...
            'LineWidth', 2, 'DisplayName', mat(i).nom);
        handlesMat(i).hMarkDisp = plot(axDisp, nan, nan, 'o', 'MarkerFaceColor', mat(i).col, ...
            'MarkerEdgeColor', 'k', 'HandleVisibility', 'off'); 
            
        % Objets TL
        handlesMat(i).hLineTL = plot(axTL, nan, nan, 'Color', mat(i).col, ...
            'LineWidth', 2, 'DisplayName', mat(i).nom);
        handlesMat(i).hMarkTL = plot(axTL, nan, nan, 'o', 'MarkerFaceColor', mat(i).col, ...
            'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
        handlesMat(i).hVLineTL = xline(axTL, nan, '--', 'Color', mat(i).col, ...
            'LineWidth', 1, 'HandleVisibility', 'off');
    end
    
    legend(axDisp, 'Location', 'northwest');
    legend(axTL, 'Location', 'southeast');

    % Premier appel
    updateAll();

    %% 4. Fonction de Mise à Jour
    function updateAll(~, ~)
        % --- A. Récupération des inputs ---
        % 1. Épaisseur
        h_mm = get(h_slider, 'Value');
        h = h_mm / 1000;
        set(lbl_h, 'String', sprintf('%.1f mm', h_mm));
        
        % 2. Fréquences
        v_min = round(get(sl_fmin, 'Value'));
        v_max = round(get(sl_fmax, 'Value'));
        
        if v_min >= v_max - 100
            v_min = v_max - 100; 
            set(sl_fmin, 'Value', v_min);
        end
        
        current_fmin = v_min;
        current_fmax = v_max;
        
        set(lbl_fmin, 'String', sprintf('%d Hz', current_fmin));
        set(lbl_fmax, 'String', sprintf('%d Hz', current_fmax));
        
        % 3. Logarithmique
        isLog = get(chk_log, 'Value');

        % --- B. Mise à jour des Axes ---
        if isLog
            set(axDisp, 'XScale', 'log');
            set(axTL, 'XScale', 'log');
        else
            set(axDisp, 'XScale', 'linear');
            set(axTL, 'XScale', 'linear'); 
        end
        
        xlim(axDisp, [current_fmin current_fmax]);
        xlim(axTL,   [current_fmin current_fmax]);
        
        % --- C. Calculs & Mise à jour des Courbes ---
        infoStr = '';
        
        for k = 1:length(mat)
            % Physique de la plaque
            D = (mat(k).E * h^3) / (12 * (1 - mat(k).nu^2));
            
            % Fréquence critique (Coincidence)
            fc = (c_air^2 / (2*pi)) * sqrt((mat(k).rho * h)/D);
            
            % Nombre d'onde de flexion
            k_f = ((omega.^2 * mat(k).rho * h) / D).^(1/4);
            
            % Loi de masse
            m_s = mat(k).rho * h;
            R_mass = 10 * log10(1 + ((omega * m_s) / (2 * Z_air)).^2);
            
            % Index pour marqueurs
            [~, idx_fc] = min(abs(f - fc));
            
            % Mise à jour data
            set(handlesMat(k).hLineDisp, 'XData', f, 'YData', k_f);
            set(handlesMat(k).hLineTL,   'XData', f, 'YData', R_mass);
            
            % Gestion visibilité marqueurs (si fc est dans la vue)
            inRange = (fc >= current_fmin && fc <= current_fmax);
            
            if inRange
                set(handlesMat(k).hMarkDisp, 'XData', f(idx_fc), 'YData', k_f(idx_fc), 'Visible', 'on');
                set(handlesMat(k).hMarkTL, 'XData', fc, 'YData', R_mass(idx_fc), 'Visible', 'on');
                set(handlesMat(k).hVLineTL, 'Value', fc, 'Visible', 'on');
            else
                set(handlesMat(k).hMarkDisp, 'Visible', 'off');
                set(handlesMat(k).hMarkTL, 'Visible', 'off');
                set(handlesMat(k).hVLineTL, 'Visible', 'off');
            end
            
            % Ajout info texte
            infoStr = [infoStr, sprintf('%s : fc = %.0f Hz\n', mat(k).nom, fc)]; %#ok<AGROW>
        end
        
        set(lbl_info, 'String', infoStr);
    end
end