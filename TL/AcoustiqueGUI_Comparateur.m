function AcoustiqueGUI_Comparateur()
    % ACOUSTIQUEGUI_COMPARATEUR_V3
    % Modification : La légende ne montre QUE les courbes visibles.
    
    clc; close all;
    
    %% 1. DONNÉES ET CONSTANTES
    c_air = 343;        
    rho_air = 1.2;      
    Z_air = rho_air * c_air; 
    
    f_theo = 10:5:20000; 
    omega_theo = 2 * pi * f_theo;
    
    % --- BASE DE DONNÉES MATÉRIAUX ---
    mat(1).nom = 'Acier';     mat(1).E = 210e9; mat(1).rho = 7800; mat(1).nu = 0.3;  mat(1).col = 'b';
    mat(2).nom = 'Alu';       mat(2).E = 70e9;  mat(2).rho = 2700; mat(2).nu = 0.33; mat(2).col = 'r';
    mat(3).nom = 'Inox';      mat(3).E = 200e9; mat(3).rho = 7900; mat(3).nu = 0.3;  mat(3).col = 'm'; 
    mat(4).nom = 'Bois LC';   mat(4).E = 11e9;  mat(4).rho = 480;  mat(4).nu = 0.3;  mat(4).col = [0.6 0.4 0.2];
    
    % Structure de données pour les fichiers expérimentaux
    expFiles = struct('nom', {}, 'f', {}, 'TL', {}, 'couleur', {}, 'handle', {});
    
    % Palette de couleurs
    fileColors = lines(10); 
    
    %% 2. INTERFACE GRAPHIQUE
    fig = figure('Name', 'Comparateur Acoustique V3', ...
                 'NumberTitle', 'off', 'Color', 'w', ...
                 'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);
    
    % --- PANNEAU DE GAUCHE ---
    pnlCtrl = uipanel(fig, 'Title', 'Paramètres', ...
                      'Units', 'normalized', 'Position', [0.01 0.01 0.25 0.98], ...
                      'BackgroundColor', 'w', 'FontSize', 10);
    
    % --- A. SECTION FICHIERS ---
    uicontrol(pnlCtrl, 'Style', 'text', 'String', '1. MESURES (Multi-sélection)', ...
              'Units', 'normalized', 'Position', [0.05, 0.96, 0.9, 0.03], ...
              'FontWeight', 'bold', 'BackgroundColor', 'w', 'HorizontalAlignment', 'left');
          
    uicontrol(pnlCtrl, 'Style', 'pushbutton', 'String', 'Charger (+)', ...
              'Units', 'normalized', 'Position', [0.05, 0.91, 0.45, 0.04], ...
              'Callback', @cb_loadData);
          
    uicontrol(pnlCtrl, 'Style', 'pushbutton', 'String', 'Reset', ...
              'Units', 'normalized', 'Position', [0.52, 0.91, 0.43, 0.04], ...
              'Callback', @cb_clearAll);
    
    lb_files = uicontrol(pnlCtrl, 'Style', 'listbox', 'String', {}, ...
              'Units', 'normalized', 'Position', [0.05, 0.71, 0.9, 0.19], ...
              'Max', 2, 'Min', 0, ... 
              'Callback', @updateAll);
    
    % --- B. SECTION MATÉRIAUX ---
    uicontrol(pnlCtrl, 'Style', 'text', 'String', '2. MATÉRIAUX', ...
              'Units', 'normalized', 'Position', [0.05, 0.66, 0.9, 0.03], ...
              'FontWeight', 'bold', 'BackgroundColor', 'w', 'HorizontalAlignment', 'left');
    
    chk_materials = [];
    for i = 1:length(mat)
        col_pos = mod(i-1, 2) * 0.5; 
        row_pos = floor((i-1)/2) * 0.04; 
        chk_materials(i) = uicontrol(pnlCtrl, 'Style', 'checkbox', 'String', mat(i).nom, ...
                                     'Units', 'normalized', ...
                                     'Position', [0.05 + col_pos, 0.62 - row_pos, 0.45, 0.03], ...
                                     'BackgroundColor', 'w', 'Value', (i==4), ...
                                     'ForegroundColor', mat(i).col, 'FontWeight', 'bold', ...
                                     'Callback', @updateAll);
    end
    
    % --- C. GÉOMÉTRIE ---
    uicontrol(pnlCtrl, 'Style', 'text', 'String', '3. ÉPAISSEUR', ...
              'Units', 'normalized', 'Position', [0.05, 0.52, 0.9, 0.03], ...
              'FontWeight', 'bold', 'BackgroundColor', 'w', 'HorizontalAlignment', 'left');
          
    lbl_h = uicontrol(pnlCtrl, 'Style', 'text', 'String', '21.0 mm', ...
              'Units', 'normalized', 'Position', [0.70, 0.52, 0.25, 0.03], ...
              'BackgroundColor', 'w', 'ForegroundColor', 'b', 'FontWeight', 'bold');
          
    sl_h = uicontrol(pnlCtrl, 'Style', 'slider', 'Min', 1, 'Max', 50, 'Value', 21, ...
                     'Units', 'normalized', 'Position', [0.05, 0.48, 0.9, 0.03], ...
                     'Callback', @updateAll);

    % --- D. TRAITEMENT & AFFICHAGE ---
    uicontrol(pnlCtrl, 'Style', 'text', 'String', '4. OPTIONS', ...
              'Units', 'normalized', 'Position', [0.05, 0.42, 0.9, 0.03], ...
              'FontWeight', 'bold', 'BackgroundColor', 'w', 'HorizontalAlignment', 'left');

    chk_smooth = uicontrol(pnlCtrl, 'Style', 'checkbox', 'String', 'Lissage (pts):', ...
                           'Units', 'normalized', 'Position', [0.05, 0.38, 0.6, 0.03], ...
                           'BackgroundColor', 'w', 'Value', 0, 'Callback', @updateAll);
                       
    edt_smooth = uicontrol(pnlCtrl, 'Style', 'edit', 'String', '5', ...
                          'Units', 'normalized', 'Position', [0.70, 0.38, 0.2, 0.03], ...
                          'Callback', @updateAll);
    
    chk_log = uicontrol(pnlCtrl, 'Style', 'checkbox', 'String', 'Axe X Logarithmique', ...
                        'Units', 'normalized', 'Position', [0.05, 0.34, 0.9, 0.03], ...
                        'BackgroundColor', 'w', 'Value', 1, 'Callback', @updateAll);
    
    uicontrol(pnlCtrl, 'Style', 'text', 'String', 'F. Min:', ...
              'Units', 'normalized', 'Position', [0.05, 0.29, 0.2, 0.025], ...
              'BackgroundColor', 'w', 'HorizontalAlignment', 'left');
    edt_fmin = uicontrol(pnlCtrl, 'Style', 'edit', 'String', '50', ...
                        'Units', 'normalized', 'Position', [0.25, 0.29, 0.2, 0.03], ...
                        'Callback', @updateAll);
                    
    uicontrol(pnlCtrl, 'Style', 'text', 'String', 'Max:', ...
              'Units', 'normalized', 'Position', [0.50, 0.29, 0.15, 0.025], ...
              'BackgroundColor', 'w', 'HorizontalAlignment', 'right');
    edt_fmax = uicontrol(pnlCtrl, 'Style', 'edit', 'String', '5000', ...
                        'Units', 'normalized', 'Position', [0.70, 0.29, 0.2, 0.03], ...
                        'Callback', @updateAll);
    
    % --- INFO BOX ---
    lbl_info = uicontrol(pnlCtrl, 'Style', 'text', 'String', 'Prêt.', ...
                         'Units', 'normalized', 'Position', [0.05, 0.02, 0.9, 0.18], ...
                         'BackgroundColor', [0.94 0.94 0.94], ...
                         'HorizontalAlignment', 'left', 'FontSize', 9);
    
    % --- ZONE GRAPHIQUE ---
    axTL = axes(fig, 'Units', 'normalized', 'Position', [0.30 0.10 0.68 0.85]);
    hold(axTL, 'on'); grid(axTL, 'on'); box(axTL, 'on');
    title(axTL, 'Transmission Loss (TL)', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel(axTL, 'Fréquence (Hz)'); ylabel(axTL, 'R (dB)');
    
    % Initialisation graphiques théoriques
    hPlotTheo = [];
    hLinesFc = []; 
    for i = 1:length(mat)
        hPlotTheo(i) = plot(axTL, NaN, NaN, '-', 'Color', mat(i).col, 'LineWidth', 2, 'DisplayName', mat(i).nom);
        % Note: HandleVisibility 'off' pour les lignes verticales, elles ne seront jamais en légende
        hLinesFc(i) = xline(axTL, NaN, ':', 'Color', mat(i).col, 'LineWidth', 1.5, 'HandleVisibility', 'off');
    end
    
    % Premier appel
    updateAll();
    
    %% 3. FONCTIONS CALLBACKS
    function cb_loadData(~, ~)
        [files, path] = uigetfile({'*.txt;*.csv;*.dat', 'Données'; '*.*', 'Tout'}, ...
                                   'Sélectionner fichiers', 'MultiSelect', 'on');
        if isequal(files, 0), return; end
        if ~iscell(files), files = {files}; end
        
        for idx = 1:length(files)
            file = files{idx};
            try
                % Tente de lire les données. 
                % On suppose format colonne 1: Freq, colonne 2: dB
                tempData = readmatrix(fullfile(path, file)); 
                if size(tempData, 2) >= 2
                    newIdx = length(expFiles) + 1;
                    colIdx = mod(newIdx - 1, size(fileColors, 1)) + 1;
                    
                    expFiles(newIdx).nom = file;
                    expFiles(newIdx).f = tempData(:,1);
                    expFiles(newIdx).TL = tempData(:,2);
                    expFiles(newIdx).couleur = fileColors(colIdx, :);
                    expFiles(newIdx).handle = plot(axTL, NaN, NaN, '-', ...
                                                   'Color', expFiles(newIdx).couleur, ...
                                                   'LineWidth', 1.5, 'DisplayName', file);
                end
            catch
                fprintf('Erreur lecture: %s\n', file);
            end
        end
        
        listStrings = {expFiles.nom};
        set(lb_files, 'String', listStrings);
        set(lb_files, 'Value', 1:length(expFiles)); % Tout sélectionner par défaut
        
        updateAll();
    end
    
    function cb_clearAll(~, ~)
        for i = 1:length(expFiles)
            if isvalid(expFiles(i).handle)
                delete(expFiles(i).handle);
            end
        end
        expFiles = struct('nom', {}, 'f', {}, 'TL', {}, 'couleur', {}, 'handle', {});
        set(lb_files, 'String', {}, 'Value', []);
        updateAll();
    end
    
    function updateAll(~, ~)
        % 1. Récupération des paramètres
        h_mm = get(sl_h, 'Value');
        h = h_mm / 1000;
        set(lbl_h, 'String', sprintf('%.1f mm', h_mm));
        
        fMin = str2double(get(edt_fmin, 'String'));
        fMax = str2double(get(edt_fmax, 'String'));
        isLog = get(chk_log, 'Value');
        
        doSmooth = get(chk_smooth, 'Value');
        sFact = round(str2double(get(edt_smooth, 'String')));
        
        % 2. Gestion des Axes
        if isLog, set(axTL, 'XScale', 'log'); else, set(axTL, 'XScale', 'linear'); end
        xlim(axTL, [fMin fMax]);
        
        infoTxt = sprintf('--- Info Calcul (h=%.1fmm) ---\n', h_mm);
        
        % --- CONSTRUCTION DE LA LÉGENDE DYNAMIQUE ---
        % On va stocker ici uniquement les handles des courbes VISIBLES
        legendHandles = []; 
        
        % 3. Affichage Mesures (Fichiers)
        selectedIndices = get(lb_files, 'Value');
        for i = 1:length(expFiles)
            if ismember(i, selectedIndices)
                y_data = expFiles(i).TL;
                if doSmooth && sFact > 1
                    y_data = movmean(y_data, sFact);
                end
                set(expFiles(i).handle, 'XData', expFiles(i).f, 'YData', y_data, 'Visible', 'on');
                
                % AJOUTER A LA LÉGENDE
                legendHandles = [legendHandles, expFiles(i).handle]; %#ok<AGROW>
            else
                set(expFiles(i).handle, 'Visible', 'off');
            end
        end
        
        % 4. Affichage Théorie (Loi de masse)
        for k = 1:length(mat)
            if get(chk_materials(k), 'Value')
                % Calcul Loi de Masse
                D = (mat(k).E * h^3) / (12 * (1 - mat(k).nu^2));
                fc = (c_air^2 / (2*pi)) * sqrt((mat(k).rho * h)/D);
                m_s = mat(k).rho * h;
                
                % Formule simple loi de masse (par incidence normale ou champ diffus simplifié)
                % Ici formule approximative incidence normale pour l'exemple
                R_mass = 10 * log10(1 + ((omega_theo * m_s) / (2 * Z_air)).^2);
                
                set(hPlotTheo(k), 'XData', f_theo, 'YData', R_mass, 'Visible', 'on');
                set(hLinesFc(k), 'Value', fc, 'Visible', 'on');
                infoTxt = [infoTxt, sprintf('%s fc: %.0f Hz\n', mat(k).nom, fc)]; %#ok<AGROW>
                
                % AJOUTER A LA LÉGENDE
                legendHandles = [legendHandles, hPlotTheo(k)]; %#ok<AGROW>
            else
                set(hPlotTheo(k), 'Visible', 'off');
                set(hLinesFc(k), 'Visible', 'off');
            end
        end
        
        set(lbl_info, 'String', infoTxt);
        
        % 5. Mise à jour finale de la légende
        if isempty(legendHandles)
            legend(axTL, 'off');
        else
            % On passe explicitement le tableau des handles visibles
            legend(axTL, legendHandles, 'Location', 'southeast', 'FontSize', 9);
        end
    end
end