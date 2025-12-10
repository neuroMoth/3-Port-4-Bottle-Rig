function Manual_Open_Valve(ValveModule,line, duration)

ModuleWrite(['ValveModule' num2str(ValveModule)], ['O' num2str(line)]);
tic
pause(duration)
toc
ModuleWrite(['ValveModule' num2str(ValveModule)], ['C' num2str(line)]);
