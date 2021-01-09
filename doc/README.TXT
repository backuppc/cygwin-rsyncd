cygwin-rsyncd-3.2.3.0: Rsyncd for Cygwin
========================================

Download and run cygwin-rsyncd-3.2.3.0_installer.exe to install
rsyncd on your WinXX client for doing BackupPC backups.

Download cygwin-rsyncd-3.2.3.0_source.zip if you want to customize
and build your own cygwin-rsyncd executable (eg: presetting some
configuration parameters for your site).

Thanks to Ray Frush, this distribution now comes with the NSIS installer,
which wraps everything in a single .exe.  (See nsis.sourceforge.net.)
This was based on the NSIS wrapper used by cwRsync.

This distribution includes rsync 3.2.3 and a handful of cygwin 3.1.7
libraries.  It was built using NSIS 3.06.1.

When you download and run cygwin-rsyncd-3.2.3.0_installer.exe, the
cygwin and rsync files are installed in c:\rsyncd.  A new windows
service called RsyncServer is created and activated (ie: run).  The
c:\rsyncd directory will have an uninstall executable which will
remove the service and installation files.

You will need to edit the c:\rsyncd\rsyncd.conf and
c:\rsyncd\rsyncd.secrets files to set your client-specific shares,
backup user name and password.  You should restart the Windows
RsyncServer service to get the new settings.

To ensure initial security, the c:\rsyncd\rsyncd.secrets file
initially has no users, and the c:\rsyncd\rsyncd.conf only allows
connections from two specific IP addresses.  So unless you edit
those two files you won't be able to connect to the rsyncd server.

If you have Windows firewall enabled then you will need to allow
rsync to listen on TCP port 873.  You can do that through the WinXX
firewall menus.  You can also make that rule specific to the BackupPC
server IP addresses, so no other hosts can contact the rsyncd server
on this client.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WARNING:
% 
% If you already have Cygwin installed then you should not
% install the cygrunsrv.exe and cygwin1.dll files. Installing
% multiple versions of the same DLL is a bad idea. Instead, you
% should manually install the rsync.exe executable in your Cygwin
% hierarchy and use the existing Cywin utilities.
%
% In fact, a package like this that contains a local cygwin1.dll
% is discouraged by the cygwin community, since if the user later
% installs the real cygwin there will be two installed cygwin1.dll's.
% Please don't complain to the cygwin user list if you do this
% and things break.
%
% Cygwin is a great package with a simple installer.  If you want
% to use Cygwin then use the setup.exe program at http://cygwin.com,
% and don't use the cygwin1.dll from this installation.  You can
% easily install rsync from the Cygwin installer.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SETTING UP BACKUPPC TO USE WINDOWS RSYNCD
=========================================

The following options will have to be set in either the global
config.pl or the per-host config.pl files. For more information
see the BackupPC documentation:

    #
    # Tell BackupPC we wish to use rsyncd: requires rsync to be running as 
    # a service/daemon on the client system
    #
    $Conf{XferMethod} = "rsyncd";

    #
    # Tell BackupPC which user name and password to use.  This should
    # match the userName:password pair in the C:\rsyncd\rsyncd.secrets
    # file on the client.
    #
    $Conf{RsyncdUserName}  = "UUU";
    $Conf{RsyncdPasswd}    = "PPP";

    #
    # Tell BackupPC which share to backup.  This should be the name
    # of the module from C:\rsyncd\rsyncd.conf on the client (the
    # name inside the square brackets).  In the sample rsynd.conf
    # file the cDrive module is the entire C drive.
    #
    $Conf{RsyncShareName}  = "cDrive";

BUILDING A NEW NSIS WRAPPED EXECUTABLE
======================================

The small tree of files to install, and the nsi script backuppc_rsync-server.nsi
are available by downloading cygwin-rsyncd-3.2.3.0_source.zip.  This isn't
program source code - it is the source tree that contains the executables
and libraries for building cygwin-rsyncd-3.2.3.0_installer.exe.

If you want to change any of the installed files (eg: configuration files),
perhaps with site-specific settings, then unzip the cygwin-rsyncd-3.2.3.0_source.zip
and edit the files as necessary.

To create the .exe installer, you will need to install NSIS from nsis.sourceforge.net.
When you run NSIS, tell it to load/run the backuppc_rsync-server.nsi file, and it
will create a .exe file that you can rename to cygwin-rsyncd-3.2.3.0_installer.exe.
To avoid version confusion, you should use a different name or version from the
standard distribution.

LICENSE
=======

The cygwin-rsyncd-3.2.3.0_source.zip contains a license.txt file
that has the licenses for cwRsync, Cygwin, Rsync and Blat.

If you install via the NSIS .exe wrapper, the license file will be
C:\rsyncd\license.txt.
