function Manual_Open_Valve(ValveModule,line, duration)

ModuleWrite(['ValveModule' num2str(ValveModule)], ['O' num2str(line)]);
tic
pause(duration/1000)
toc
ModuleWrite(['ValveModule' num2str(ValveModule)], ['C' num2str(line)]);