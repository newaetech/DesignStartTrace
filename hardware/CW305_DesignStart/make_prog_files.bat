@REM Create MCS file for base board QSPI flash memory
@REM Requires existing bit file to convert
@REM Has to call Vivado in batch mode, then run TCL script


call vivado -mode batch -source make_prog_files.tcl -notrace
