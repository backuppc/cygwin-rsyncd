; Leveraged heavily from ITeF!x Consulting rsync-server.nsi 2.0.3 (https://www.itefix.no)
; Modifed by Ray Frush, Avago Technologies. ray.frush@avagotech.com

Unicode True

!define VERSION "3.2.3.1"
!define SVCNAME "RsyncServer"
!define SVCUSR  "SvcRsync"
!define PACKAGE "RsyncServer"

!define NAME "BackupPC"
!define UNINSTPROG "uninstall_${NAME}_${PACKAGE}.exe"
!define REGROOT "Software\BackupPC"

!include "${NSISDIR}\Include\WinMessages.nsh"

SetCompressor /SOLID LZMA

!include "MUI.nsh"
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

!include "FileFunc.nsh"
!insertmacro GetParameters
!insertmacro GetOptions

; Request application privileges for Windows Vista
RequestExecutionLevel admin

Name "${NAME} ${PACKAGE} ${VERSION}"
OutFile "cygwin-rsyncd-${VERSION}_installer.exe"
InstallDirRegKey HKLM ${REGROOT} "InstallDirectory"
AutoCloseWindow true

VIAddVersionKey  "ProductName" "${NAME}"
VIAddVersionKey  "CompanyName" "BackupPC"
VIAddVersionKey  "FileDescription" "${NAME} ${PACKAGE}"
VIAddVersionKey  "LegalCopyright" "Copyright by respective holders (see license.txt)"
VIAddVersionKey  "FileVersion" "${VERSION}"
VIProductVersion "${VERSION}.0"

Var installtype
var SystemDrive


Function .onInit

	ReadEnvStr $SystemDrive SYSTEMDRIVE
	StrCpy $INSTDIR '$SystemDrive\rsyncd'

	StrCpy $installtype "fresh"

;	Init_Cont_A:
;	# Check if icw base is installed 
;	ReadRegStr $0 HKLM "${REGROOT}\Base" "version"
;	IfErrors 0 Init_Cont_B
;	MessageBox MB_OK|MB_ICONSTOP  "${NAME} Base package is required for ${NAME} ${PACKAGE}." /SD IDOK
;	Abort
;	
;	Init_Cont_B:	
	# Check for previous package installations
	ReadRegStr $0 HKLM "${REGROOT}\${PACKAGE}" "version"
	IfErrors Init_End
	StrCpy $installtype "upgrade"	

;	Init_Cont_C:
;	# Check if user / password is defined via command line
;	${GetParameters} $0
;	${GetOptions} $0 "/u="  $svcuser
;	${GetOptions} $0 "/p="  $svcpassword
;	IfErrors 0 Init_End
;	MessageBox MB_OK|MB_ICONSTOP  "No service account and password are specified." /SD IDOK
;	Abort

	Init_End:
	
FunctionEnd

Function un.onInit
FunctionEnd

# Install section
Section "${NAME} ${PACKAGE}"

	SetAutoClose true

	StrCmp $installtype "upgrade" 0 Install_A
	IfSilent +2
	Banner::show /NOUNLOAD "Upgrading ${PACKAGE} ..."
	
	Call UpgradePackage
	Goto Install_End
	
	Install_A:
	IfSilent +2
	Banner::show /NOUNLOAD "Installing ${PACKAGE} ..."
	
	Call InstallPackage
	
	Install_End:
	Banner::destroy

	WriteUninstaller "$INSTDIR\${UNINSTPROG}"

SectionEnd

# Uninstall section
Section "Uninstall"

	SetAutoClose true

	DetailPrint "Remove registry keys"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME} ${PACKAGE}"
	DeleteRegKey HKLM "${REGROOT}\${PACKAGE}"

	DetailPrint "Remove uninstaller"
	Delete $INSTDIR\${UNINSTPROG}

	DetailPrint "Stop and remove NT services"
	nsExec::ExecToLog '"$INSTDIR\Bin\cygrunsrv" -E ${SVCNAME}'
	nsExec::ExecToLog '"$INSTDIR\Bin\cygrunsrv" -R ${SVCNAME}'

		
	Call un.DeleteFiles

SectionEnd

Function InstallPackage

	Call InstallFiles

	SetOutPath $INSTDIR
	File rsyncd.conf
	
	Call SetupService
	
	; Write the version into the registry
	WriteRegStr HKLM "${REGROOT}\${PACKAGE}" "Version" "${VERSION}"
;	WriteRegStr HKLM "${REGROOT}\${PACKAGE}" "ServiceAccount" $svcuser

	; Write the uninstall keys for Windows
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME} ${PACKAGE}" "DisplayName" "${NAME} ${PACKAGE} (remove only)"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME} ${PACKAGE}" "UninstallString" '"${UNINSTPROG}"'

	Banner::destroy
	
FunctionEnd

!macro SetUserAttributes SERVER_NAME USERNAME ATTRIBUTES
  # Change user account attributes
  System::Call '*(i "${ATTRIBUTES}")i.R0'
  System::Call 'netapi32::NetUserSetInfo(w "${SERVER_NAME}",w "${USERNAME}",i 1008, \
i R0,*i.r0)i.r1'
  System::Free $R0
!macroend
	
!define UF_SCRIPT                               0x000001
!define UF_ACCOUNTDISABLE                       0x000002
!define UF_HOMEDIR_REQUIRED                     0x000008
!define UF_LOCKOUT                              0x000010
!define UF_PASSWD_NOTREQD                       0x000020
!define UF_PASSWD_CANT_CHANGE                   0x000040
!define UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED      0x000080
!define UF_TEMP_DUPLICATE_ACCOUNT               0x000100
!define UF_NORMAL_ACCOUNT                       0x000200
!define UF_INTERDOMAIN_TRUST_ACCOUNT            0x000800
!define UF_WORKSTATION_TRUST_ACCOUNT            0x001000
!define UF_SERVER_TRUST_ACCOUNT                 0x002000
!define UF_DONT_EXPIRE_PASSWD                   0x010000
!define UF_MNS_LOGON_ACCOUNT                    0x020000
!define UF_SMARTCARD_REQUIRED                   0x040000
!define UF_TRUSTED_FOR_DELEGATION               0x080000
!define UF_NOT_DELEGATED                        0x100000
!define UF_USE_DES_KEY_ONLY                     0x200000
!define UF_DONT_REQUIRE_PREAUTH                 0x400000
!define UF_PASSWORD_EXPIRED                     0x800000

Function SetupService
	
;	# Check if user exists (exit code 0)
;	nsExec::ExecToStack "net user $svcuser"
;	pop $0	
;	IntCmp $0 0 +2
;	nsExec::ExecToLog 'net user $svcuser $svcpassword /ADD /COMMENT:"cwRsync Service Account"'
;	# The first two should always be there, set don't expire password
;	StrCpy $0 0
;	IntOp $0 $0 + ${UF_NORMAL_ACCOUNT}
;	IntOp $0 $0 + ${UF_DONT_EXPIRE_PASSWD}
;	# Use IntOp to add more from the above list of definitions
;	!insertmacro SetUserAttributes "" "$svcuser" "$0"
		
;	DetailPrint "Grant required privileges to the service account $svcuser"
;	nsExec::ExecToLog '"$INSTDIR\bin\ntrights" +r SeServiceLogonRight -u $svcuser'
	
	nsExec::Exec '"$INSTDIR\bin\cygrunsrv" -E ${SVCNAME}'
	nsExec::Exec '"$INSTDIR\bin\cygrunsrv" -R ${SVCNAME}'
	
	DetailPrint "Installing rsync daemon as a service"
	nsExec::ExecToLog '"$INSTDIR\bin\cygrunsrv" -I ${SVCNAME} -c "$INSTDIR" -p "$INSTDIR\bin\rsync.exe" -a "--config rsyncd.conf --daemon --no-detach" -o -t auto -e "CYGWIN=nontsec binmode" -1 "$INSTDIR\rsyncd-stdin.log" -2 "$INSTDIR\rsyncd-stderr.log" -y "tcpip" -f "Rsync - open source utility that provides fast incremental file transfer"'
 	nsExec::ExecToLog '"$INSTDIR\bin\cygrunsrv" --verbose --start ${SVCNAME}'
 	nsExec::ExecToLog '"$INSTDIR\bin\cygrunsrv" --verbose --query ${SVCNAME}'
	nsExec::Exec '"$INSTDIR\bin\notify.bat"'

;	DetailPrint "Granting service account full permission on the installation directory"
;	nsExec::ExecToLog '"$INSTDIR\bin\xcacls" "$INSTDIR" /T /E /G $svcuser:C /Y'

FunctionEnd

Function UpgradePackage

	DetailPrint "Stop/Remove ${SVCNAME} service"
	nsExec::ExecToLog '"$INSTDIR\Bin\cygrunsrv" -E ${SVCNAME}'
	nsExec::Exec '"$INSTDIR\bin\cygrunsrv" -R ${SVCNAME}'
	
	Call InstallFiles
	
	DetailPrint "Installing rsync daemon as a service"
	nsExec::ExecToLog '"$INSTDIR\bin\cygrunsrv" -I ${SVCNAME}  -c "$INSTDIR" -p "$INSTDIR\bin\rsync.exe" -a "--config rsyncd.conf --daemon --no-detach" -o -t auto -e "CYGWIN=nontsec binmode" -1 "$INSTDIR\rsyncd-stdin.log" -2 "$INSTDIR\rsyncd-stderr.log" -y "tcpip" -f "Rsync - open source utility that provides fast incremental file transfer"'


	DetailPrint "Start ${SVCNAME} service"
	nsExec::ExecToLog '"$INSTDIR\Bin\cygrunsrv" -S ${SVCNAME}'

	; Update the version info 
	WriteRegStr HKLM "${REGROOT}\${PACKAGE}" "Version" "${VERSION}"

FunctionEnd

Function InstallFiles


	SetOutPath "$INSTDIR"
	File /oname=$INSTDIR\rsyncd.conf rsyncd.conf
	File /oname=$INSTDIR\rsyncd.secrets rsyncd.secrets
	File /oname=$INSTDIR\license.txt license.txt

    SetOutPath "$INSTDIR\bin"
	File /oname=$INSTDIR\bin\notify.bat bin\notify.bat
	File /oname=$INSTDIR\bin\sendemail.ps1 bin\sendemail.ps1

	File /oname=$INSTDIR\bin\cygiconv-2.dll bin\cygiconv-2.dll
	File /oname=$INSTDIR\bin\cygpopt-0.dll bin\cygpopt-0.dll
	File /oname=$INSTDIR\bin\cygrunsrv.exe bin\cygrunsrv.exe
	File /oname=$INSTDIR\bin\cygwin1.dll bin\cygwin1.dll
	File /oname=$INSTDIR\bin\cyglz4-1.dll bin\cyglz4-1.dll
	File /oname=$INSTDIR\bin\cygzstd-1.dll bin\cygzstd-1.dll
	File /oname=$INSTDIR\bin\cygxxhash-0.dll bin\cygxxhash-0.dll
	File /oname=$INSTDIR\bin\cygcrypto-1.1.dll bin\cygcrypto-1.1.dll
	File /oname=$INSTDIR\bin\cygz.dll bin\cygz.dll
	File /oname=$INSTDIR\bin\rsync.exe bin\rsync.exe

	SetOutPath "$INSTDIR\etc"
	File /oname=$INSTDIR\etc\fstab etc\fstab
	
	SetOutPath "$INSTDIR\doc"
	File /oname=$INSTDIR\doc\README.TXT doc\README.TXT
	File /oname=$INSTDIR\doc\rsync.html doc\rsync.html
	File /oname=$INSTDIR\doc\rsyncd.conf.html doc\rsyncd.conf.html

		
FunctionEnd

Function un.DeleteFiles

	Delete $INSTDIR\rsyncd.conf
	Delete $INSTDIR\rsyncd.secrets
	Delete $INSTDIR\license.txt

	Delete $INSTDIR\bin\notify.bat
	Delete $INSTDIR\bin\sendemail.ps1

	Delete $INSTDIR\bin\cygiconv-2.dll
	Delete $INSTDIR\bin\cygpopt-0.dll
	Delete $INSTDIR\bin\cyglz4-1.dll
	Delete $INSTDIR\bin\cygzstd-1.dll
	Delete $INSTDIR\bin\cygxxhash-0.dll
	Delete $INSTDIR\bin\cygcrypto-1.1.dll
	Delete $INSTDIR\bin\cygz.dll
	Delete $INSTDIR\bin\cygrunsrv.exe
	Delete $INSTDIR\bin\cygwin1.dll
	Delete $INSTDIR\bin\rsync.exe

	Delete $INSTDIR\etc\fstab

	Delete $INSTDIR\doc\README.TXT
	Delete $INSTDIR\doc\rsync.html
	Delete $INSTDIR\doc\rsyncd.conf.html

	Delete $INSTDIR\info.txt
	Delete $INSTDIR\rsyncd.lock
	Delete $INSTDIR\rsyncd.log
	Delete $INSTDIR\rsyncd-stderr.log
	Delete $INSTDIR\rsyncd-stdin.log

	RMDir $INSTDIR\doc
	RMDir $INSTDIR\etc
	RMDir $INSTDIR\bin
	RMDir $INSTDIR
		
FunctionEnd
