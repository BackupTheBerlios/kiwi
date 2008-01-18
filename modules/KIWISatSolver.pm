#================
# FILE          : KIWISatSolver.pm
#----------------
# PROJECT       : OpenSUSE Build-Service
# COPYRIGHT     : (c) 2006 SUSE LINUX Products GmbH, Germany
#               :
# AUTHOR        : Marcus Schaefer <ms@suse.de>
#               :
# BELONGS TO    : Operating System images
#               :
# DESCRIPTION   : This module is used to integrate the sat solver
#               : for suse pattern and package solving tasks. As
#               : the satsolver is something SUSE specific the following
#               : code will only be used on systems where satsolver
#               : exists. The KIWIPattern module makes use of this
#               : module functions and will switch back to the old
#               : style pattern solving code if satsolver is not
#               : present
#               :
# STATUS        : Development
#----------------
package KIWISatSolver;
#==========================================
# Modules
#------------------------------------------
use strict;
use KIWILog;
use KIWIQX;

#==========================================
# Plugins
#------------------------------------------
BEGIN {
	$KIWISatSolver::haveSaT = 1;
	eval {
		require SaT;
		SaT -> import;
	};
	if ($@) {
		$KIWISatSolver::haveSaT = 0;
	}
	if (! $KIWISatSolver::haveSaT) {
		package SaT;
	}
}

#==========================================
# Constructor
#------------------------------------------
sub new {
	# ...
	# Construct a new KIWISatSolver object if satsolver is present.
	# The solver object is used to queue pattern and package solve
	# requests which gets solved by the contents of a sat solvable
	# which is either created by the repository metadata contents
	# or used directly from the repository if it is provided
	# ---
	#==========================================
	# Object setup
	#------------------------------------------
	my $this  = {};
	my $class = shift;
	bless  $this,$class;
	#==========================================
	# Module Parameters
	#------------------------------------------
	my $kiwi    = shift;
	my $xml     = shift;
	my $pref    = shift;
	my $urlref  = shift;
	#==========================================
	# Constructor setup
	#------------------------------------------
	my $solvable; # sat solvable file name
	my $pool;     # sat pool object
	my $repo;     # sat repo object
	my $solver;   # sat solver object
	my $job;      # sat job queue
	my @solved;   # solve result
	if (! defined $kiwi) {
		$kiwi = new KIWILog("tiny");
	}
	$kiwi -> info ("Setting up SaT solver...\n");
	if (! defined $xml) {
		$kiwi -> error ("--> No XML reference specified");
		$kiwi -> failed ();
		return undef;
	}
	if (! $KIWISatSolver::haveSaT) {
		$kiwi -> error ("--> No SaT plugin installed");
		$kiwi -> failed ();
		return undef;
	}
	if (! defined $pref) {
		$kiwi -> error ("--> Invalid package/pattern reference");
		$kiwi -> failed ();
		return undef;
	}
	if (! defined $urlref) {
		$kiwi -> error ("--> Invalid repository URL reference");
		$kiwi -> failed ();
		return undef;
	}
	#==========================================
	# Create and cache sat solvable
	#------------------------------------------
	$solvable = $xml -> getInstSourceSatSolvable ($urlref);
	if (! defined $solvable) {
		return undef;
	}
	#==========================================
	# Create SaT repository and job queue
	#------------------------------------------
	if (! open (FD,$solvable)) {
		$kiwi -> error  ("--> Couldn't open solvable: $!");
		$kiwi -> failed ();
		return undef;
	}
	$pool = new SaT::_Pool;
	$repo = $pool -> createRepo('repo');
	$repo -> addSolvable (*FD); close FD;
	$solver = new SaT::Solver ($pool);
	$pool -> createWhatProvides();
	$job = new SaT::Queue;
	$job -> queuePush ( $SaT::SOLVER_INSTALL_SOLVABLE );
	foreach my $p (@{$pref}) {
		my $name = "pattern:".$p;
		if (! $job -> queuePush ( $pool -> selectSolvable ($repo,$name))) {
			$kiwi -> error ("--> Failed to queue job: $name");
			$kiwi -> failed ();
			return undef;
		}
	}
	#==========================================
	# Solve the job(s)
	#------------------------------------------
	$solver -> solve ($job);
	my $list = $solver -> getInstallList ($pool);
	foreach my $name (@{$list}) {
		if ($name =~ /^pattern:(.*)/) {
			$kiwi -> info ("Including pattern: $1");
			$kiwi -> done ();
		} else {
			push (@solved,$name);
		}
	}
	#==========================================
	# Store object data
	#------------------------------------------
	$this->{kiwi}    = $kiwi;
	$this->{xml}     = $xml;
	$this->{urllist} = $urlref;
	$this->{plist}   = $pref;
	$this->{job}     = $job;
	$this->{repo}    = $repo;
	$this->{solver}  = $solver;
	$this->{result}  = \@solved;
	return $this;
}

#==========================================
# getPackages
#------------------------------------------
sub getPackages {
	# /.../
	# return solved list
	# ----
	my $this   = shift;
	my $result = $this->{result};
	my @result = ();
	if (defined $result) {
		return @{$result};
	}
	return @result;
}

1;