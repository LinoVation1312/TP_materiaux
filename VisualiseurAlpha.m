function VisualiseurAlpha
    % VISUALISEURSIMPLE - Version Avancée
    % - Chargement récursif
    % - Sélection multiple des courbes à afficher
    % - Réglage dynamique de Fmin et Fmax
    
    % --- 1. Variables partagées ---
    DonneesMemoire = struct('Nom', {}, 'Freq', {}, 'Alpha', {});
    
    % --- 2. Construction de l'interface ---
    fig = uifigure('Name', 'Visualiseur Alpha', 'Position', [100 100 1000 600]);
    
    % Grille principale
    gl = uigridlayout(fig, [1 2]);
    gl.ColumnWidth = {250, '1x'};
    
    % -- Panneau Gauche (Contrôles) --
    pnlControl = uipanel(gl, 'Title', 'Contrôles');
    pnlControl.Layout.Row = 1;
    pnlControl.Layout.Column = 1;
    
    % 1. Boutons de gestion (Haut)
    btnLoad = uibutton(pnlControl, ...
        'Text', 'Charger Dossier', ...
        'Position', [10 520 230 35], ...
        'BackgroundColor', [0.6 0.8 1], ...
        'ButtonPushedFcn', @ActionChargerDossier);
        
    btnClear = uibutton(pnlControl, ...
        'Text', 'Effacer Tout', ...
        'Position', [10 480 230 30], ...
        'FontColor', 'red', ...
        'ButtonPushedFcn', @ActionEffacer);
        
    % 2. Réglages Fréquence (Milieu)
    uilabel(pnlControl, 'Text', 'Plage Freq (Hz) :', ...
        'Position', [10 445 100 20], 'FontWeight', 'bold');
        
    uilabel(pnlControl, 'Text', 'Min:', 'Position', [10 425 30 20]);
    efMin = uieditfield(pnlControl, 'numeric', ...
        'Position', [40 425 50 20], ...
        'Value', 0, ...               % Valeur par défaut
        'ValueChangedFcn', @MettreAJourGraphique); % Mise à jour auto
        
    uilabel(pnlControl, 'Text', 'Max:', 'Position', [110 425 30 20]);
    efMax = uieditfield(pnlControl, 'numeric', ...
        'Position', [140 425 50 20], ...
        'Value', 30, ...              % Valeur par défaut (ex: 30Hz)
        'ValueChangedFcn', @MettreAJourGraphique); % Mise à jour auto

    % 3. Liste des fichiers (Bas)
    uilabel(pnlControl, 'Text', 'Sélectionnez pour afficher :', ...
        'Position', [10 395 230 20], 'FontWeight', 'bold');
        
    % NOTE : 'MultiSelect' est activé ici
    lstBox = uilistbox(pnlControl, ...
        'Position', [10 50 230 340], ...
        'MultiSelect', 'on', ...      % Permet de choisir plusieurs items
        'ValueChangedFcn', @MettreAJourGraphique); % Réagit au clic
    
    % Label d'état
    lblStatus = uilabel(pnlControl, 'Text', 'Prêt.', ...
        'Position', [10 10 230 30], 'FontColor', [0.4 0.4 0.4]);
        
    % -- Panneau Droit (Graphique) --
    pnlGraph = uipanel(gl, 'BorderType', 'none');
    pnlGraph.Layout.Row = 1;
    pnlGraph.Layout.Column = 2;
    
    ax = uiaxes(pnlGraph);
    ax.Position = [10 10 700 580]; 
    title(ax, 'Analyse Spectrale');
    xlabel(ax, 'Fréquence (Hz)');
    ylabel(ax, 'Amplitude');
    grid(ax, 'on');
    
    % --- 3. Logique Applicative ---
    
    function ActionChargerDossier(~, ~)
        dossierRacine = uigetdir(pwd, 'Sélectionnez le dossier PARENT');
        if dossierRacine == 0, return; end
        
        lblStatus.Text = 'Chargement...';
        drawnow;
        
        fichiersTrouves = dir(fullfile(dossierRacine, '**', 'Alpha.txt'));
        
        if isempty(fichiersTrouves)
            uialert(fig, 'Aucun fichier "Alpha.txt" trouvé.', 'Info');
            lblStatus.Text = '0 fichier.';
            return;
        end
        
        compteur = 0;
        nouveauxNoms = {}; % Pour présélectionner les nouveaux ajouts
        
        for i = 1:length(fichiersTrouves)
            cheminComplet = fullfile(fichiersTrouves(i).folder, fichiersTrouves(i).name);
            [~, nomDossier] = fileparts(fichiersTrouves(i).folder);
            
            % Vérifie si ce nom existe déjà pour éviter les doublons exacts
            nomsExistants = {DonneesMemoire.Nom};
            if any(strcmp(nomsExistants, nomDossier))
                continue; % On saute si déjà chargé
            end

            try
                data = readmatrix(cheminComplet, 'NumHeaderLines', 1);
                idx = length(DonneesMemoire) + 1;
                DonneesMemoire(idx).Nom = nomDossier;
                DonneesMemoire(idx).Freq = data(:, 1);
                DonneesMemoire(idx).Alpha = data(:, 2);
                
                nouveauxNoms{end+1} = nomDossier; %#ok<AGROW>
                compteur = compteur + 1;
            catch
                % Ignorer erreurs
            end
        end
        
        lblStatus.Text = [num2str(compteur) ' ajoutés.'];
        
        % Mise à jour de la liste
        tousLesNoms = {DonneesMemoire.Nom};
        lstBox.Items = tousLesNoms;
        
        % Astuce : Sélectionner automatiquement tout ce qui est chargé
        % (Si vous préférez ne rien sélectionner, commentez la ligne ci-dessous)
        lstBox.Value = tousLesNoms; 
        
        MettreAJourGraphique();
    end

    function ActionEffacer(~, ~)
        DonneesMemoire = struct('Nom', {}, 'Freq', {}, 'Alpha', {});
        lstBox.Items = {};
        MettreAJourGraphique();
        lblStatus.Text = 'Tout effacé.';
    end

    function MettreAJourGraphique(~, ~)
        % Cette fonction est appelée par le bouton Charger, 
        % la ListBox (clic) et les champs Fmin/Fmax (changement valeur).
        
        % 1. Nettoyage
        cla(ax);
        legend(ax, 'off');
        
        if isempty(DonneesMemoire)
            return;
        end
        
        % 2. Récupérer la sélection utilisateur
        selection = lstBox.Value; % Retourne un cell array de noms
        
        if isempty(selection)
            return; % Rien à afficher
        end
        
        hold(ax, 'on');
        couleurs = lines(length(DonneesMemoire)); % Palette fixe
        
        % 3. Boucle d'affichage intelligente
        foundPlot = false;
        for k = 1:length(DonneesMemoire)
            nomCourant = DonneesMemoire(k).Nom;
            
            % On ne trace que si le nom est dans la liste "selection"
            if ismember(nomCourant, selection)
                semilogx(ax, DonneesMemoire(k).Freq, DonneesMemoire(k).Alpha, ...
                    'Color', couleurs(k,:), ...
                    'LineWidth', 1.5, ...
                    'DisplayName', nomCourant);
                foundPlot = true;
            end
        end
        hold(ax, 'off');
        
        % 4. Application des limites Fmin / Fmax
        fMin = efMin.Value;
        fMax = efMax.Value;
        
        % Vérification basique pour éviter crash si Min >= Max
        if fMin >= fMax
            fMax = fMin + 1; 
        end
        xlim(ax, [fMin fMax]);
        
        if foundPlot
            legend(ax, 'show', 'Location', 'northeast', 'Interpreter', 'none');
        end
    end
end