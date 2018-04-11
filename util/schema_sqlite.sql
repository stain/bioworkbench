create table script_run (
	script_run_id	   text primary key,
        script_filename    text,
	log_filename       text,
	hostname	   text,
	script_run_dir	   text,
        swift_version      text,
        final_state        text,
        start_time         text,
        duration           real
);

create table script_run_argument (
			script_run_id		text references script_run (script_run_id),
			arg				text,
			value			text
);

create table script_run_annot_text (
			script_run_id		text references script_run (script_run_id),
			key				text,
			value			text
);

create table script_run_annot_numeric (
			script_run_id		text references script_run (script_run_id),
			key				text,
			value			numeric
);

create table app_exec (
	app_exec_id			text primary key,
  script_run_id   		text references script_run(script_run_id),
	app_name			text,
	execution_site			text,
	start_time			text,
	duration			real,
	staging_in_duration		real,
	staging_out_duration		real,
	work_directory			text
);

create table app_exec_annot_text (
			app_exec_id		text references app_exec (app_exec_id),
			key				text,
			value			text
);

create table app_exec_annot_numeric (
			app_exec_id		text references app_exec (app_exec_id),
			key				text,
			value			numeric
);

create table app_exec_argument (
	app_exec_id			text references app_exec (app_exec_id),
	arg_position			integer,
	app_exec_arg			text
);

create table resource_usage (
       app_exec_id	    		text primary key references app_exec (app_exec_id),
       real_secs	       		real,
       kernel_secs             		real,
       user_secs	       		real,
       percent_cpu             		integer,
       max_rss	       	       		integer,
       avg_rss	       			integer,
       avg_tot_vm	       		integer,
       avg_priv_data     		integer,
       avg_priv_stack    		integer,
       avg_shared_text   		integer,
       page_size	       		integer,
       major_pgfaults    		integer,
       minor_pgfaults    		integer,
       swaps	       			integer,
       invol_context_switches		integer,
       vol_waits			integer,
       fs_reads				integer,
       fs_writes			integer,
       sock_recv			integer,
       sock_send			integer,
       signals				integer,
       exit_status			integer
);

create table file (
       file_id		text primary key,
       host		text,
       name		text,
       size		integer,
       modify		integer
);

create table file_annot_text (
			file_id		text references file (file_id),
			key				text,
			value			text
);

create table file_annot_numeric (
			file_id		text references file (file_id),
			key				text,
			value			numeric
);

create table staged_in (
       app_exec_id			text references app_exec (app_exec_id),
       file_id 				text references file (file_id)
);

create table staged_out (
       app_exec_id			text references app_exec (app_exec_id),
       file_id				text references file (file_id)
);

CREATE TABLE input(
	script_run_id text references script_run (script_run_id),
	lib_forward varchar,
	lib_reverse varchar
);

CREATE TABLE gff( 
	file_id text references file (file_id),
	id varchar,
	name varchar,
	parent varchar,
	biotype varchar,
	ccdsid varchar,
	description varchar,
	end varchar,
	feature varchar,
	frame varchar,
	gene_id varchar,
	havana_gene varchar,
	havana_transcript varchar,
	havana_version varchar,
	logic_name varchar,
	score varchar,
	seqname varchar,
	source varchar,
	start varchar,
	strand varchar,
	tag varchar,
	transcript_id varchar,
	transcript_support_level varchar,
	version varchar
);

CREATE TABLE vcf (
	file_id text REFERENCES file (file_id), 
	chrom integer, 
	pos integer, 
	ref varchar, 
	alt varchar, 
	vartype varchar, 
	dp integer, 
	mq integer, 
	af, 
	effect varchar, 
	impact varchar,
 	codon varchar, 
	aa varchar, 
	gene varchar, 
	trid varchar, 
	filter varchar, 
	vcf_id INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE "vcf_temp" (file_id text references file (file_id), 
	chrom integer, 
	pos integer, 
	ref  varchar, 
	alt varchar, 
	vartype varchar, 
	dp integer, 
	mq integer, 
	af, 
	effect varchar, 
	impact varchar, 
	codon varchar, 
	aa varchar, 
	gene varchar, 
	trid varchar, 
	filter varchar,
	vcf_id INTEGER
);

CREATE VIEW vcf_gff AS select   v.chrom,
         v.pos,
         v.ref,
         v.alt,
         v.vartype,
         v.dp,
         v.mq,
         v.af,
         v.effect,
         v.impact,
         v.codon,
         v.aa,
         v.gene,
         trim(v.trid, 'transcript:') as trid,
         g.Name as name, g.biotype,
         v.filter,
         a.script_run_id,
         v.file_id        
from     vcf v
natural join file f
natural join staged_out o
natural join app_exec a
--where a.script_run_id like 'loss-run006-3737171381'
left join gff g on v.trid = g.ID
where v.effect not like 'INTRON'
and v.effect not like 'SYNONYMOUS%';

--gff g, vcf v 
--where g.ID = v.trid;

-- View: script_arg
CREATE VIEW script_arg AS select 
        s.script_run_id,        
	s.script_filename,
        a1.value as ref,
        a2.value as libF,
        a3.value as libR,
        a4.value as gtf,
        a5.value as t,
        a6.value as op
from script_run s
     left outer join script_run_argument a1 on
        s.script_run_id = a1.script_run_id
        and a1.arg like 'ref'
    left outer join script_run_argument a2 on
        s.script_run_id = a2.script_run_id
        and a2.arg like '1'
    left outer join script_run_argument a3 on
        s.script_run_id = a3.script_run_id
        and a3.arg like '2'
    left outer join script_run_argument a4 on
        s.script_run_id = a4.script_run_id
        and a4.arg like 'gtf'
    left outer join script_run_argument a5 on
        s.script_run_id = a5.script_run_id
        and a5.arg like 't'
    left outer join script_run_argument a6 on
        s.script_run_id = a6.script_run_id
        and a6.arg like 'op';

-- View: provenance_graph_edge
CREATE VIEW provenance_graph_edge as
	select app_exec_id as parent, file_id as child from staged_out
	union
	select file_id as parent, app_exec_id as child from staged_in;

-- View: app_arg
CREATE VIEW app_arg AS select
     a.script_run_id,
     a.app_name,
     g1.app_exec_arg as arg_1,
     g2.app_exec_arg as arg_2,
     g3.app_exec_arg as arg_3,
     g4.app_exec_arg as arg_4,
     g5.app_exec_arg as arg_5,
     g6.app_exec_arg as arg_6
from
    app_exec a
    inner join script_run s on
        a.script_run_id = s.script_run_id
    left outer join app_exec_argument g1 on
        a.app_exec_id = g1.app_exec_id
        and g1.arg_position = 1
    left outer join app_exec_argument g2 on
        a.app_exec_id = g2.app_exec_id
        and g2.arg_position = 2
    left outer join app_exec_argument g3 on
        a.app_exec_id = g3.app_exec_id
        and g3.arg_position = 3
    left outer join app_exec_argument g4 on
        a.app_exec_id = g4.app_exec_id
        and g4.arg_position = 4
    left outer join app_exec_argument g5 on
        a.app_exec_id = g5.app_exec_id
        and g5.arg_position = 5
    left outer join app_exec_argument g6 on
        a.app_exec_id = g6.app_exec_id
        and g6.arg_position = 6;


