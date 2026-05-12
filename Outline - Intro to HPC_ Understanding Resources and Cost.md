# **Intro to HPC: Understanding Resources and Cost**

## Familiarize yourself with the tools available to you that help understand how efficiently you are using the requested resources and how those resources used translate to the cost of a job.

# **Outline**

## **What’s important to know?**

- How do I know what resources I need?  
- How do I figure out how much those resources cost to use?  
- What factors affect the cost?  
- Common terms  
  - CPU/Processor/Core  
  - CPU hour  
  - “SLURM Account”  
  - UMRCP  
  - Partitions  
- What are the limits/constraints?  
  - Are there any guardrails?  
- How do I track how much I’ve used?  
- Are there free accounts?

## **What tools do we have to help with this?**

### **Web-Based**

- [HPC Cost Calculator](https://um-jglad.github.io/um-hpc-cost-calc/)  
  - Identify cost by job type  
  - SLURM script example based on calculated resources  
- [SPH HPC Usage (PI’s only)](https://hpc-usage.bio.sph.umich.edu/)  
  - ARC Cluster usage broken down by PI  
- [Resource Management Portal (RMP)](http://portal.arc.umich.edu)  
  - Manage and visualize available resources on a project

### **Cluster/CLI**

my\_accounts           shows accounts you are a member of along with limits

my\_usage              shows your usage across accounts

my\_account\_billing    shows approximate accumulated charges for an account

my\_account\_usage		shows a breakdown of usage by user over a period of time for an account

my\_account\_resources  shows all resources in use for an account

my\_job\_estimate       calculates an estimated job cost from a slurm script

my\_job\_header         include in job scripts to capture environment variables

my\_job\_statistics     shows detailed job information and resource efficiency

#### **Examples:**

##### **$ my\_account\_billing \-v {ACCOUNT}**

support has used approximately $5.43 since 2026-03-01 

\------------------------------------------------------

uniqname  dollars  percentage

     cja     1.33       24.46

mrchampe     1.28       23.47

jtcannon     1.21       22.32

  maxmil     0.56       10.27

 smehsen     0.22        4.14

  wcasto     0.22        4.02

 kgweiss     0.14        2.57

  jonpot     0.12        2.22

lkealoha     0.10        1.90

     ram     0.10        1.85

   jsonk     0.08        1.53

mmiranda     0.04        0.71

   jglad     0.02        0.32

 bbattey     0.01        0.13

chribrwn     0.00        0.09

carleski     0.00        0.01

cconwill     0.00        0.01

   total     5.43      100.00

##### **$ my\_account\_usage \-A {ACCOUNT}**

Collecting data. Please wait....

Account:     support

Report Type: billing

 From 2026-02-01 to 2026-04-01, this month is an estimate as of 2026-03-24 09:24:44

     user,                                     Name,    2026-02,    2026-03,       Total

\----------------------------------------------------------------------------------------

    total,                                         ,       8.53,       5.43,      13.97

  bbattey,                        Bradford R Battey,       0.00,       0.01,       0.01

 carleski,                             Rob Carleski,       0.00,       0.00,       0.00

   casebw,                             Brandon Case,       0.33,       0.00,       0.33

 cconwill,                            Chris Conwill,       0.00,       0.00,       0.00

 chribrwn,                        Christopher Brown,       0.01,       0.00,       0.01

      cja,                      Charles J Antonelli,       1.52,       1.33,       2.85

    cjasw,                     Charles Antonelli sw,       0.03,       0.00,       0.03

    jglad,                         Jacob Gladfelter,       0.07,       0.02,       0.09

   jonpot,                          Jonathan Potter,       0.00,       0.12,       0.12

    jsonk,                               Jason Sonk,       1.33,       0.08,       1.41

 jtcannon,                             James Cannon,       0.00,       1.21,       1.21

  kgweiss,                          Kenneth G Weiss,       1.61,       0.14,       1.75

  lilienc,                   Christopher Lilienthal,       0.44,       0.00,       0.44

 lkealoha,                              Leslie Bell,       0.51,       0.10,       0.62

   maxmil,                         Maxwell Milliken,       0.30,       0.56,       0.86

    maxsw,                         Maxwell Milliken,       0.24,       0.00,       0.24

 mmiranda,                          Malcolm Miranda,       0.06,       0.04,       0.10

 mrchampe,                              Mark Champe,       1.99,       1.28,       3.26

      ram,                           Richard Merkle,       0.00,       0.10,       0.10

  smehsen,                               Sam Mehsen,       0.07,       0.22,       0.30

  vnegrea,                            Vasile Negrea,       0.01,       0.00,       0.01

   wcasto,                            William Casto,       0.01,       0.22,       0.23

     wdob,                      William Dobrowolski,       0.00,       0.00,       0.00

##### **$ my\_usage**

\------------------------------------------------------

Usage from 2026-03-01 to 2026-04-01:

\------------------------------------------------------

  Account                     Login      Used

 \--------------------------- \---------- \------------- 

                     support      jglad        $0.02

##### **$ my\_job\_statistics {JOBID}**

Job summary for JobID 44545298 on the greatlakes cluster for jglad

Job name: ondemand/sys/dashboard/sys/bc\_desktop\_basic

\--------------------------------------------------------------------------

Job submit time:     03/09/2026 09:46:36

Job start time:      03/09/2026 09:46:37

Job end time:        03/09/2026 10:18:52

Job running time:    00:32:15

State:               COMPLETED

Exit code:           0

On nodes:            gl3014

                     (1 nodes with 2 cores per node)

CPU Utilized:        00:03:32

CPU Efficiency:      5.48% of 01:04:30 total CPU time (cores \* walltime)

Memory Utilized:     1.35 GiB

Memory Efficiency:   11.26% of 12.00 GiB

Cost:                $0.02

\--------------------------------------------------------------------------

##### **$ my\_job\_estimate \-c {CORES} \--mem={MEMORY\_GB} \-t {DD-HH:MM:SS}**

\--------------------------------------------------

Job Detail Summary:

\--------------------------------------------------

Partition:     standard

Total Nodes:   1

Total Cores:   2

Total Memory:  12288.0 MiB

Walltime:      0 day(s)

               00 hour(s)

               30 minute(s)

               00 second(s)

\--------------------------------------------------

Cost Estimate:

\--------------------------------------------------

Total:  $0.02 ($0.015026999999999999) for 0.5 hours

NOTE: This price estimate assumes your job runs for the full walltime. 

Cost is subject to change.

## **Common Terms**

**CPU/Processor/Core:** In the HPC world, this refers to **a single processing unit** that will do work. Some have taken to calling this a “Processing Element” or PE. You may typically think of a CPU/Processor as the chip inside your laptop that has many cores, and that’s still correct. When we talk about this in an HPC context, we typically say CPU/Core to refer to an individual core on the chip. This is the unit you will use to define your resource requirements when submitting a job to the cluster. For parallel environments, there are various ways to define the resource needs; I’ve found [this explainer from CECI-HPC](https://support.ceci-hpc.be/doc/SubmittingJobs/SlurmFAQ/#q05-how-do-i-create-a-parallel-environment) to be the most helpful.

**CPU hour**: refers to the use of a defined amount of resources for one hour. The amount of resources that define the CPU hour depend on the partition or type of resource you’re trying to use. On the standard partition, a single billable CPU hour is defined as 1 CPU and 7GB of memory. More details about the various partitions across the cluster can be found on [ARC’s Service Rate page](https://its.umich.edu/advanced-research-computing/rates). When ARC advertises the [UMRCP](https://its.umich.edu/advanced-research-computing/research-computing-package/service-allocations) as “80,000 CPU Hours”, what they mean is that with the allocation they provide you could use 1 core and 7GB of memory for 80,000 hours. On Great Lakes, this roughly translates to $1,200.

**UMRCP**: [University of Michigan Research Computing Package](https://its.umich.edu/advanced-research-computing/research-computing-package). This is the no-cost allocation available to every researcher, on all U-M campuses, with at least one of these roles:

*     Professors with an active appointment  
*     Faculty instructors and lecturers with an active appointment  
*     Emeritus faculty  
*     Guest faculty who are visiting for one to two years  
*     Principal investigators (PI) (e.g., research scientists) on self-funded research activities  
*     PostDocs with their own research grant

**SLURM Account:** SLURM is the underlying software on the cluster that facilitates job scheduling and cluster communication. When ARC uses the term “Account”, they’re typically referring to a SLURM account, which is how an individual's usage is tracked. Everyone must be associated with a SLURM account in order to submit a job to the cluster. Typically a SLURM account will be associated with a faculty member or PI, but may also be a group or project based account.

**Partitions:** These are simply a way for ARC to section out resources based on their type. Each cluster will have a number of partitions, with names generally explaining their primary feature. For example, Great Lakes has a standard partition, which has typical CPUs and Memory counts, a Large Mem partition, which has a large memory-to-core ratio, and various GPU partitions, each based on the type of GPU available. These allow ARC to specify different limits/constraints and billing units for each type of hardware, and for you to specify which hardware you need when submitting a job.

## **How do I know what resources I need?**

This is generally trial and error. You can estimate based on the dataset and how you’re breaking up the work, based on what your local device has and what’s been limiting you, or by using interactive sessions with tools that show active usage. Submitting test batch jobs is typically the best way to get a true estimate. For serial code, you only ever need 1 CPU per task. If you’ve implemented parallel functions, then you can test performance gains across multiple CPUs in some test runs.

### **Interactive tools**

Using tools like RStudio’s memory indicator or commandline based tools like top/htop are easy first steps to understanding memory and CPU utilization. You can do a test/example run of your code and monitor the usage to get a rough idea of what you should request. Keep in mind that this doesn’t work great for parallel code, especially in RStudio. 

### **Batch job tests**

A simple way to get an accurate estimate of your resource needs is to simply run some test batch jobs. This can be as simple as shrinking parameters, sample sizes, datasets, etc, and running a single batch job with overestimated resources. When the batch job completes, it will typically send an email with some statistics about how well the resources requested matched the actual resource usage. Because these jobs are only running your code, and no other programs/interfaces, it’s more true to what you need to request for a full run. From this test, you can generally extrapolate out and estimate the overall needs of your job(s).

We can also use command line based tools to review the efficiency of your jobs later on. Tools like my\_job\_statistics, seff, and [reportseff](https://github.com/troycomi/reportseff) can help get an idea of how well various jobs are running, and their cost.

## **How do I determine costs?**

Cost is primarily determined by the amount of resources you hold on to for the length of time you hold on to them. ARC has tied certain resources together to make up a “billing unit” for the various partitions and resources they have available. To get an idea of what your job will cost, you can use command line based tools like my\_job\_estimate or web based tools like the [HPC Cost Calculator](https://um-jglad.github.io/um-hpc-cost-calc/). These will take your estimated resource needs and convert them to a dollar amount based on the various billing units and weights ARC applies.

### **What factors affect the cost?**

**You are charged for the resources you hold, for the duration you hold on to them for.**

As mentioned above, the various resources have different billing weights tied to them. The amount of cpus, memory, or GPUs requested will all have an impact on the cost of the job. Looking at ARCs published [rates for Great Lakes](https://its.umich.edu/advanced-research-computing/high-performance-computing/great-lakes/rates), we can start to see what that looks like. Each row in the table outlines the amount of resources bundled into a billing unit for the various partitions. For example, the standard partition ties 1 CPU and 7GB of memory into a billing unit. This means that if you request 1 CPU and 4GB for a job, the cost will be the same as if you request 1 CPU and 7GB. If you go above 7GB, the cost will begin to increase. If you request 2 CPUs, you can request up to 14GB without the cost changing, until you creep above 14GB. It’s important to remember here that even though you *can* request up to that amount without the cost changing, it doesn't mean you *should*. Only request what your job actually needs to be a good steward of this shared system.

Time also affects the cost of the job, but only for the duration of the actual run time, not the requested time. If you request 8 hours, and your job completes in 6, you are only charged for the 6 hours you held on to the resources for. Once a batch job completes, it releases the resources back to the scheduler. This is important because it’s the one resource you can — and should — safely overestimate on. ARC will not extend the run time of a job, so if your work does not finish in the requested time limit, the job will end with a TIMEOUT state and the work will cease. If you did not implement any method for checkpointing, the work may need to start over from the beginning. Because of this, it’s a good idea to slightly overestimate the amount of time you think your job will need. The biggest penalty of this *might* be some extra time waiting in the queue, but that may be well worth it compared to rerunning your entire analysis/simulation/etc.

## **Are there limits or constraints to usage?**

Yes. There are limits at the “root account”, subaccount, and individual users levels. Each of these can be customized to an extent by the owner of the account. Check the [Great Lakes](https://documentation.its.umich.edu/arc-hpc/greatlakes/user-guide) and [Armis2](https://documentation.its.umich.edu/arc-hpc/armis2) user guides for exact limits based on the partitions being used. For example, Great Lakes standard partitions have a default “root account” limit of 

- 500 cores  
- 3,500 GB Memory  
- 2 Week Wall Time

This means that if FacultyA has 2 accounts, facultyA0 and facultyA1, **both accounts combined** can use a maximum of the two resources above for a maximum individual job runtime of 2 weeks. If UserA on facultyA0 is using 300 CPUs, UserB has a maximum of 200 CPUs they can use while UserA’s jobs are running.

In the example above, facultyA0 and facultyA1 are examples of “subaccounts”. A faculty member or PI can have multiple subaccounts that fall under their “root account”. These allow different spending limits, funding shortcodes, or users to be added to the various accounts they may have.

### **What about guardrails to avoid overspending?**

To help avoid runoff spending, for example by accidentally submitting a job array of 10,000 instead of 1,000, we can set limits on subaccounts or individual users on a subaccount. If FacultyA has a $1,000 monthly limit set for facultyA1, they can choose to set individual limits on any member of that account. UserA can have a $250 monthly limit, and UserB can have a $400 limit. Note that the limits do not have to equal the overall subaccount monthly limit; this allows flexibility in the event that UserB doesn’t actually need all $400 one month.

You can see how these limits can be beneficial, but can also sometimes get in the way of research. If other users need close to their full individual limit, one or both may have jobs held up in the queue until jobs end early and funds are freed up, the next month starts and limits reset, or we intervene to increase the subaccount monthly limit. This is why it’s important to set reasonable limits on subaccounts and for researchers to actively participate in job cost estimates up front.

While monthly limits tend to be the most popular, ARC can also set yearly or one-time limits as well. See the documentation from ARC on [SLURM Billing Limits](https://documentation.its.umich.edu/arc-hpc/armis2/slurm-billing-limits) for more details.

## **How do I track my usage?**

There are various tools made available via the command line interface (CLI) to look at usage, the easiest being the my\_usage command. By default, all of these commands will show your usage or the account usage for the current month. My\_account\_usage is the most flexible, providing flags for start/end windows to show usage overtime for a given account.

The web-based [Resource Management Portal](http://portal.arc.umich.edu) (RMP) can show overall account usage, but isn’t great at showing individual usage unless there are user-level limits on the account. 