//=======================================
// Interface definition for libsatsolver
//---------------------------------------
%module SaT
%{
extern "C"
{
#include "policy.h"
#include "bitmap.h"
#include "evr.h"
#include "hash.h"
#include "poolarch.h"
#include "pool.h"
#include "poolid.h"
#include "pooltypes.h"
#include "queue.h"
#include "solvable.h"
#include "solver.h"
#include "repo.h"
#include "repo_solv.h"
}
#include <sstream>
%}

//==================================
// Typemap: Allow FILE* as PerlIO
//----------------------------------
#if defined(SWIGPERL)
%typemap(in) FILE* {
    $1 = PerlIO_findFILE(IoIFP(sv_2io($input)));
}
#endif

//==================================
// Extends
//----------------------------------
%include "bitmap.h"
%include "evr.h"
%include "hash.h"
%include "poolarch.h"
%include "poolid.h"
%include "pooltypes.h"
%include "pool.h"
%include "queue.h"
%include "solvable.h"
%include "solver.h"
%include "repo.h"
%include "repo_solv.h"
//==================================
// Extend _Pool struct
//----------------------------------
%extend _Pool {
    _Pool() {
        return pool_create();
    }

    ~_Pool() {
        pool_free (self);
    }

    void set_arch(const char *arch) {
        pool_setarch(self, arch);
    }

    int installable (Solvable *s) {
        return pool_installable(self,s);
    }

    void createWhatProvides() {
        pool_createwhatprovides(self);
    }

    Solvable *id2solvable(Id p) {
        return pool_id2solvable(self, p);
    }

    Id selectSolvable (Repo *repo, char *name) {
        Id id;
        Queue plist;
        int i, end;
        Solvable *s;
        Pool *pool;
        pool = self;
        id = str2id(pool, name, 1);
        queue_init( &plist);
        i = repo ? repo->start : 1;
        end = repo ? repo->start + repo->nsolvables : pool->nsolvables;
        for (; i < end; i++) {
            s = pool->solvables + i;
            if (!pool_installable(pool, s)) {
                continue;
            }
            if (s->name == id) {
                queue_push(&plist, i);
            }
        }
        prune_best_version_arch(pool, &plist);
        if (plist.count == 0) {
            //printf("unknown package '%s'\n", name);
            return -1;
        }
        id = plist.elements[0];
        queue_free(&plist);
        return id;
    }

    Repo* createRepo(const char *reponame) {
        return repo_create(self, reponame);
    }
};
%newobject pool_create;
%delobject pool_free;

//==================================
// Extend Queue struct
//----------------------------------
%extend Queue {
    Queue() {
        Queue *q = new Queue();
        queue_init(q);
        return q;
    }

    ~Queue() {
        queue_free(self);
    }

    Queue* clone() {
        Queue *t = new Queue();
        queue_clone(t, self);
        return t;
    }

    Id shift() {
        return queue_shift(self);
    }
  
    bool queuePush (Id id) {
        if (id >= 0) {
            queue_push(self, id);
            return 1;
        } else {
            return 0;
        }
    }

    bool isEmpty() {
        return (self->count == 0);
    }

    void clear() {
        queue_empty(self);
    }
};
%newobject queue_init;
%delobject queue_free;

//==================================
// Extend Solvable struct
//----------------------------------
%extend Solvable {
    Id id() {
        if (!self->repo) {
            return 0;
        }
        return self - self->repo->pool->solvables;
    }

    %ignore name;
    const char * name() {
        return id2str(self->repo->pool, self->name);
    }

    %rename("to_s") toString();
    const char * toString() {
        if ( self->repo == NULL ) {
            return "<unknown>";
        }
        return solvable2str(self->repo->pool, self);
    }
}

//==================================
// Extend Solver struct
//----------------------------------
%extend Solver {
    Solver ( Pool *pool, Repo *installed = 0 ) {
        return solver_create(pool, installed);
    }

    ~Solver() { solver_free(self); }

    void solve (Queue *job) {
        solver_solve(self, job);
    }

    void printDecisions() {
        printdecisions(self);
    }

    SV* getInstallList (Pool *pool) {
        int b = 0;
        AV *myav = newAV();
        SV *mysv = 0;
        SV *res  = 0;
        int len = self->decisionq.count;
        for (b = 0; b < len; b++) {
            Id p = self->decisionq.elements[b];
            if (p < 0) {
                continue; // ignore conflict
            }
            if (p == SYSTEMSOLVABLE) {
                continue; // ignore system solvable
            }
            Solvable *s = self->pool->solvables + p;
            //printf ("SOLVER NAME: %d %s\n",p,id2str(pool, s->name));
            const char* myel = (char*)id2str(pool, s->name);
            mysv = sv_newmortal();
            mysv = perl_get_sv (myel,TRUE);
            sv_setpv(mysv, myel);
            av_push (myav,mysv);
        }
        res = newRV((SV*)myav);
        sv_2mortal (res);
        return res;
    }
};

//==================================
// Extend Repo struct
//----------------------------------
%nodefaultdtor Repo;
%extend Repo {
    Solvable *add_solvable() {
        return pool_id2solvable(self->pool, repo_add_solvable(self));
    }

    void addSolvable (FILE *fp) {
        repo_add_solv(self, fp);
    }
};

//==================================
// Typemap: Allow Id struct as input
//----------------------------------
%typemap(in) Id {
    $1 = (int) NUM2INT($input);
    printf("Received an integer : %d\n",$1);
}   