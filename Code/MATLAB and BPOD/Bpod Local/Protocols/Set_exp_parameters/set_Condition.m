function settings_struct = set_Condition(settings_struct)
%SET_CONDITION checks if a condition has been selected. If so, then it changes all other options to 'null'
% Inputs:
%   settings_struct - The settings structure containing GUI fields
%
% Outputs: 
%   settings_struct - updated conditions listed and selected conditioned edited

arguments
    settings_struct struct
end

global BpodSystem   % get global BpodSystem object

varName = sprintf('CONDITION_CODE');
choice = settings_struct.GUI.(varName); 
conditionOptions = settings_struct.GUIMeta.(varName).String;

if choice ~= 1 && ~strcmp('null',conditionOptions(1))
    selectCondition = conditionOptions(choice);
    newConditions = {'null', 'null', 'null'};
    newConditions(choice) = selectCondition; 

    settings_struct.GUIMeta.(varName).String = newConditions; 
end

end

