@Echo Off
Rem
Echo -----------------------Check.Bat---------------------------------
Echo The results for julia bfbs.jl runs on various test files
Echo is about to be directed into the file "tstResults.txt".
Echo.
Echo After this Check.Bat file has finished the latest results
Echo can be checked against "correctResults.txt" by switching
Echo from cmd shell to powershell shell with; -
Echo.
Echo powershell
Echo.
Echo and then running the following single line comparison script
Echo.
echo powershell -Command '$f1 = Get-Content ".\correctResults.txt"; $f2 = Get-Content ".\tstResults.txt"; Compare-Object -ReferenceObject $f1 -DifferenceObject $f2'
Echo.
Echo If there is no output from the powershell comparison script then
Echo the files are the same and nothing has changed in the results
Echo output by the bfbs.jl code (at least for the test file cases).
Echo.
Echo Running julia code to generate tstResults.txt
Echo.
.\tst.bat > tstResults.txt
