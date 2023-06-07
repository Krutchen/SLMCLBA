# SLMCLBA - GLBA Fork
Performant listen based armour for the Secondlife Military Community.

This repository contains the most up-to-date and lag-free scripts for LBA, as well as the documentation provided by upstream. 

# Migrating from Legacy LBA
The version of LBA that is currently distributed is no longer maintained.

Simply delete your old LBA scripts, and follow the instructions below under "Usage."

The GLBA scripts to use as a replacement for the legacy scripts is as follows:

| Legacy Script Name | GLBA Script |
|--------------------|-------------|
|LBA-Light-Deployable-vX.XX.lsl|Use GLBA-Slim|
|LBA-Light-vX.XX.lsl|Use GLBA-Slim|
|LBA-Slim-v.X.XX.lsl|Use GLBA-Slim|
|LBA-v.2.32.lsl|Use GLBA-Vehicles|
|LBA-D-v2.32-rc3.lsl|Directional GLBA has not yet been released, continue using legacy|

## Compatibility
GLBA is fully compatible with **all** LBA-compliant weaponry, vehicles, and deployables.

# Usage

## GLBA-Slim.lsl: Deployable Objects

Create a new script in your deployable and copy/paste the LSL code in `GLBA-Slim.lsl` into it, and hit "Save".

Take the deployable into your inventory and deploy it as needed.

## GLBA-Vehicles.lsl: Vehicles

GLBA-Vehicles is meant to be used for vehicles that are meant to be driven, such as tanks, gunships, air ships, boats, cars, golf carts, etc.

Create a new script in your deployable and copy/paste the LSL code in `GLBA-Vehicles.lsl` into it, and hit "Save".

Take the vehicle into your inventory and rez it where you want.

# Contributing

## Basics
For those new to git, or the open source GitHub experience, I highly recommend you complete the basic [GitHub "Hello World" Tutorial](https://guides.github.com/activities/hello-world/) before contributing.

Once or if you understand the essentials of git and/or GitHub, follow this tutorial to fork this repository:

["Forking" a Repository](https://guides.github.com/activities/forking/)

Once you have created a fork, and modified it, you can submit a pull request by going to [uncertain-string/SLMCA/pulls](https://github.com/uncertain-string/SLMCLBA/pulls) and hitting "New pull request." 

GitHub has provided this tutorial on [How to Collaborate using Pull Requests from a Fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork)

If you need help, contact `frick.teardrop`.

## Help
If you have any further questions, contact `frick.teardrop` in Second Life. Frick is always happy to help anybody understand open source projects, and how git (and collaborating within GitHub) works.


# Performance Results

The numbers represented in these tables are script time, the average number of seconds (over around a 30 minute window) that each script performs work during a simulator frame. 

The results are sorted by the difference between idle and active states. The lowest difference between states wins, as the difference is the _actual_ amount of active script time that the script uses per frame during combat.

Idle state is after rezzing and waiting 10 minutes for script time to settle.

Active state is after being hit with 5,000 collisions & listen events over 5 minutes.

You will notice that homesteads have higher script time. This is because there is 1/4th of the CPU time normally available per frame as they are homesteads. Thanks to optimizations from the mono project, the realized difference in performance is minimal between homesteads and full sims.

## Full Sim Hybrid RC Statistics

![image](https://user-images.githubusercontent.com/28276562/148669447-ed65f290-3571-46c6-9d1b-6e28d6a8462b.png)

## Homestead Hybrid RC Statistics

![image](https://user-images.githubusercontent.com/28276562/148669457-07c7ced3-ba6f-4fd0-bf9d-f4077c0c75b1.png)

## Notes
You will notice that full sims report a higher script time average, this is because full sims have 4 times the capacity of a homestead, so they schedule far more script executions per frame, and allocate far more CPU time for scripts per frame than homesteads.
