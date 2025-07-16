function Manual_OdGen_Valve(ValveModule,line, sign)
% sign=1 --> ON
% sign=2 --> OFF
if sign==1
    ModuleWrite(['ValveModule' num2str(ValveModule)], ['O' num2str(line)]);
else
    ModuleWrite(['ValveModule' num2str(ValveModule)], ['C' num2str(line)]);
end