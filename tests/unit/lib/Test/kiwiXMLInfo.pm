#================
# FILE          : kiwiXMLInfo.pm
#----------------
# PROJECT       : OpenSUSE Build-Service
# COPYRIGHT     : (c) 2011 Novell Inc.
#               :
# AUTHOR        : Robert Schweikert <rschweikert@novell.com>
#               :
# BELONGS TO    : Operating System images
#               :
# DESCRIPTION   : Unit test implementation for the KIWIXMLInfo module.
#               : Certain queries require root priveleges, thus these queries
#               : are not implemented as unit tests. Manual testing is required
#               : to verify query functionality for
#               :     -- packages
#               :     -- patterns
#               :     -- repo-patterns
#               :     -- size
#               :
# STATUS        : Development
#----------------
package Test::kiwiXMLInfo;

use strict;
use warnings;
use XML::LibXML;

use Common::ktLog;
use Common::ktTestCase;
use base qw /Common::ktTestCase/;

use KIWICommandLine;
use KIWIXMLInfo;

#==========================================
# Constructor
#------------------------------------------
sub new {
	# ...
	# Construct new test case
	# ---
	my $this = shift -> SUPER::new(@_);
	my $baseDir = $this -> getDataDir() . '/xmlInfo/';
	$this -> {baseDir} = $baseDir;
	$this -> {kiwi}    = new Common::ktLog();

	return $this;
}

#==========================================
# test_ctor_improperArg
#------------------------------------------
sub test_ctor_improperArg {
	# ...
	# Test the XMLInfo object constructor
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmdL = new KIWICommandLine($kiwi);
	# No argument for CommandLine object
	my $info = new KIWIXMLInfo($kiwi, $cmdL);
	my $msg = $kiwi -> getMessage();
	my $expectedMsg = 'Invalid KIWICommandLine object, no configuration '
		. 'directory.';
	$this -> assert_str_equals($expectedMsg, $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('error', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('failed', $state);
	# Test this condition last to get potential error messages
	$this -> assert_null($info);
}

#==========================================
# test_ctor_missArg
#------------------------------------------
sub test_ctor_missArg {
	# ...
	# Test the XMLInfo object constructor
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	# No argument for CommandLine object
	my $info = new KIWIXMLInfo($kiwi);
	my $msg = $kiwi -> getMessage();
	my $expectedMsg = 'KIWIXMLInfo: expecting KIWICommandLine object as '
		. 'second argument.';
	$this -> assert_str_equals($expectedMsg, $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('error', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('failed', $state);
	# Test this condition last to get potential error messages
	$this -> assert_null($info);
}

#==========================================
# test_getTree_improperArg
#------------------------------------------
sub test_getTree_improperArg {
	# ...
	# Test getting a tree
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd  = $this -> __getCmdl();
	$cmd -> setConfigDir($this -> {baseDir});
	my $info = $this -> __getInfoObj($cmd);
	# Supply improper argument
	my @invalidOpts = ('ola');
	my $res = $info -> getXMLInfoTree(@invalidOpts);
	my $msg = $kiwi -> getMessage();
	my $expectedMsg = 'Expecting ARRAY_REF as first argument for info '
		. 'requests.';
	$this -> assert_str_equals($expectedMsg, $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('error', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('failed', $state);
	$this -> assert_null($res);
}

#==========================================
# test_getTree_invalidReq
#------------------------------------------
sub test_getTree_invalidReq {
	# ...
	# Test getting a tree
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd  = $this -> __getCmdl();
	$cmd -> setConfigDir($this -> {baseDir});
	my $info = $this -> __getInfoObj($cmd);
	# Supply improper argument
	my @invalidOpts = ('ola');
	my $res = $info -> getXMLInfoTree(\@invalidOpts);
	my $expectedMsg = 'Requested information option ola not supported, '
		. 'ignoring.';
	my $warnMsg = $kiwi -> getWarningMessage();
	$this -> assert_str_equals($expectedMsg, $warnMsg);
	my $state = $kiwi -> getWarningState();
	$this -> assert_equals('skipped', $state);
	my $errMsg = $kiwi -> getErrorMessage();
	$expectedMsg = 'None of the specified information options are available.';
	$this -> assert_str_equals($expectedMsg, $errMsg);
	my $msg = $kiwi -> getMessage();
	$expectedMsg = "Choose between the following:\n"
		. "--> packages       :List of packages to be installed\n"
		. "--> patterns       :List configured patterns\n"
		. "--> profiles       :List profiles\n"
		. "--> repo-patterns  :List available patterns from repos\n"
		. "--> size           :List install/delete size estimation\n"
		. "--> sources        :List configured source URLs\n"
		. "--> types          :List configured types\n"
		. "--> version        :List name and version\n";
	$this -> assert_str_equals($expectedMsg, $msg);
	$state = $kiwi -> getState();
	$this -> assert_str_equals('failed', $state);
	$this -> assert_null($res);
}

#==========================================
# test_getTree_noArg
#------------------------------------------
sub test_getTree_noArg {
	# ...
	# Test getting a tree
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd  = $this -> __getCmdl();
	$cmd -> setConfigDir($this -> {baseDir});
	my $info = $this -> __getInfoObj($cmd);
	# Do not supply an argument
	my $res = $info -> getXMLInfoTree();
	my $msg = $kiwi -> getMessage();
	my $expectedMsg = 'No information requested, nothing todo.';
	$this -> assert_str_equals($expectedMsg, $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('error', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('failed', $state);
	$this -> assert_null($res);
}

#==========================================
# test_printTree_improperArg
#------------------------------------------
sub test_printTree_improperArg {
	# ...
	# Test getting a tree
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd  = $this -> __getCmdl();
	$cmd -> setConfigDir($this -> {baseDir});
	my $info = $this -> __getInfoObj($cmd);
	# Supply improper argument
	my @invalidOpts = ('ola');
	my $res = $info -> printXMLInfo(@invalidOpts);
	my $msg = $kiwi -> getMessage();
	my $expectedMsg = 'Expecting ARRAY_REF as first argument for info '
		. 'requests.';
	$this -> assert_str_equals($expectedMsg, $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('error', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('failed', $state);
	$this -> assert_null($res);
}

#==========================================
# test_printTree_invalidReq
#------------------------------------------
sub test_printTree_invalidReq {
	# ...
	# Test getting a tree
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd  = $this -> __getCmdl();
	$cmd -> setConfigDir($this -> {baseDir});
	my $info = $this -> __getInfoObj($cmd);
	# Supply improper argument
	my @invalidOpts = ('ola');
	my $res = $info -> printXMLInfo(\@invalidOpts);
	my $expectedMsg = 'Requested information option ola not supported, '
		. 'ignoring.';
	my $warnMsg = $kiwi -> getWarningMessage();
	$this -> assert_str_equals($expectedMsg, $warnMsg);
	my $state = $kiwi -> getWarningState();
	$this -> assert_equals('skipped', $state);
	my $errMsg = $kiwi -> getErrorMessage();
	$expectedMsg = 'None of the specified information options are available.';
	$this -> assert_str_equals($expectedMsg, $errMsg);
	my $msg = $kiwi -> getMessage();
	$expectedMsg = "Choose between the following:\n"
		. "--> packages       :List of packages to be installed\n"
		. "--> patterns       :List configured patterns\n"
		. "--> profiles       :List profiles\n"
		. "--> repo-patterns  :List available patterns from repos\n"
		. "--> size           :List install/delete size estimation\n"
		. "--> sources        :List configured source URLs\n"
		. "--> types          :List configured types\n"
		. "--> version        :List name and version\n";
	$this -> assert_str_equals($expectedMsg, $msg);
	$state = $kiwi -> getState();
	$this -> assert_str_equals('failed', $state);
	$this -> assert_null($res);
}

#==========================================
# test_printTree_noArg
#------------------------------------------
sub test_printTree_noArg {
	# ...
	# Test getting a tree
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd  = $this -> __getCmdl();
	$cmd -> setConfigDir($this -> {baseDir});
	my $info = $this -> __getInfoObj($cmd);
	# Do not supply an argument
	my $res = $info -> printXMLInfo();
	my $msg = $kiwi -> getMessage();
	my $expectedMsg = 'No information requested, nothing todo.';
	$this -> assert_str_equals($expectedMsg, $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('error', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('failed', $state);
	$this -> assert_null($res);
}

#==========================================
# test_profileInfo
#------------------------------------------
sub test_profileInfo {
	# ...
	# Test to ensure we get the proper profile information
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd  = $this -> __getCmdl();
	$cmd -> setConfigDir($this -> {baseDir});
	my $info = $this -> __getInfoObj($cmd);
	my @requests = ('profiles');
	my $tree = $info -> getXMLInfoTree(\@requests);
	my $expectedMsg = '<imagescan><profile name="first" description="a '
		. 'profile"/><profile name="second" description="another profile"/>'
		.  '</imagescan>';
	$this -> assert_not_null($tree);
	$this -> assert_str_equals($expectedMsg, $tree -> toString());
	my $msg = $kiwi -> getMessage();
	$this -> assert_str_equals('No messages set', $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('none', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('No state set', $state);
}

#==========================================
# test_typesInfo
#------------------------------------------
sub test_typesInfo {
	# ...
	# Test to ensure we get the proper type information back
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd  = $this -> __getCmdl();
	$cmd -> setConfigDir($this -> {baseDir});
	my $info = $this -> __getInfoObj($cmd);
	my @requests = ('types');
	my $tree = $info -> getXMLInfoTree(\@requests);
	my $expectedMsg = '<imagescan><type name="iso" primary="true" '
		. 'boot="isoboot/suse-11.4"/><type name="oem" primary="false" '
		. 'boot="oemboot/suse-11.4"/><type name="xfs" primary="false"/>'
		. '</imagescan>';
	$this -> assert_not_null($tree);
	$this -> assert_str_equals($expectedMsg, $tree -> toString());
	my $msg = $kiwi -> getMessage();
	$this -> assert_str_equals('No messages set', $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('none', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('No state set', $state);
}

#==========================================
# test_sourcesInfo
#------------------------------------------
sub test_sourcesInfo {
	# ...
	# Test to ensure we get the proper source information
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd  = $this -> __getCmdl();
	$cmd -> setConfigDir($this -> {baseDir});
	my $info = $this -> __getInfoObj($cmd);
	my @requests = ('sources');
	my $tree = $info -> getXMLInfoTree(\@requests);
	my $expectedMsg = '<imagescan><source path="/tmp" type="rpm-dir"/>'
		. '</imagescan>';
	$this -> assert_not_null($tree);
	$this -> assert_str_equals($expectedMsg, $tree -> toString());
	my $msg = $kiwi -> getMessage();
	$this -> assert_str_equals('No messages set', $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('none', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('No state set', $state);
}

#==========================================
# test_versionInfo
#------------------------------------------
sub test_versionInfo {
	# ...
	# Test to ensure we get the proper version information
	# ---
	my $this = shift;
	my $kiwi = $this -> {kiwi};
	my $cmd  = $this -> __getCmdl();
	$cmd -> setConfigDir($this -> {baseDir});
	my $info = $this -> __getInfoObj($cmd);
	my @requests = ('version');
	my $tree = $info -> getXMLInfoTree(\@requests);
	my $expectedMsg = '<imagescan><image version="1.0.0" '
		. 'name="test-xml-infod"/></imagescan>';
	$this -> assert_not_null($tree);
	$this -> assert_str_equals($expectedMsg, $tree -> toString());
	my $msg = $kiwi -> getMessage();
	$this -> assert_str_equals('No messages set', $msg);
	my $msgT = $kiwi -> getMessageType();
	$this -> assert_str_equals('none', $msgT);
	my $state = $kiwi -> getState();
	$this -> assert_str_equals('No state set', $state);
}

#==========================================
# Private helper methods
#------------------------------------------
#==========================================
# __getInfoObj
#------------------------------------------
sub __getInfoObj {
	# ...
	# Helper mehod to create a valid XMLInfo object
	# ---
	my $this = shift;
	my $cmd  = shift;
	my $info = new KIWIXMLInfo($this -> {kiwi}, $cmd);

	return $info;
}

#==========================================
# __getCmdl
#------------------------------------------
sub __getCmdl {
	# ...
	# Helper to create a command line object
	# ---
	my $this = shift;
	return new KIWICommandLine($this -> {kiwi});
}


1;