function S = load_bpod_settings(S)

if isempty(fieldnames(S)) % If /

        subj = BpodSystem.GUIData.SubjectName;
        dir = ['C:\Users\Chad Samuelsen\Documents\Github\Bpod Local\Data\FakeSubject\Set_param_Ortho_Set_1\Session Settings\DefaultSettings.mat'];
        temp = load(dir);
        S = temp.ProtocolSettings; clear temp;

        % init an empty cell array to hold names of gui fields to remove
        fields = {};
        % remove ability to rename valve stimuli
        for i = 1:8
            fieldname = sprintf('valve_line_%d', i);

            fields{end+1} = fieldname;

            fieldname = sprintf('Valve_%d', i);

            fields{end+1} = fieldname;
        end

        S.GUIMeta = rmfield(S.GUIMeta, fields); % Using a cell array

        S.GUI = rmfield(S.GUI, fields);

        S.GUIPanels = rmfield(S.GUIPanels, {'Current_valve_assignments','Manual_Taste_Valves'});

        BpodSystem.ProtocolSettings = S;
    end

    % port_1 is the instance of the class Port1
    port_1 = LateralPort(1);
    % port_3 is the instance of the class Port3
    port_3 = LateralPort(3);
    % center_port the instance of the class center_port
    center_port = CenterPort;

    correct_port = CorrectPort;
    incorrect_port = IncorrectPort;

end
