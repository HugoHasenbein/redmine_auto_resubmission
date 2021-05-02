# redmine_auto_resubmission

Redmine plugin to resubmit / follow up (German: "Wiedervorlage") an issue after it has been put away. Choose from list, if you want the issue to reappear tomorrow, in a week, or in a month. The time intervals can be chosen freely. On resubmission the issue is "touched", the status is changed according to configuration and a preconfigured text can be added to a new issue-journal.

**Caveat:** the plugin needs configuration and possibly cron, though resubmissions can be calculated via one click on a daily base.

![PNG that represents a quick overview](/doc/Overview.png)


### Release Note 

From now (version 1.0.7) on the rake task needs to be provided a user id for a user having privileges to view, edit issues for resubmission. Also workflows should not block custom fields.

### Use case

A job (iisue) is done. Need to follow up in a week or two? Mark the issue to reappear then. The issue will turn up in your current issues then.

### Install

1. download plugin and copy plugin folder redmine_auto_resubmission go to Redmine's plugins folder 

2. restart server f.i.

`sudo /etc/init.d/apache2 restart`

### Uninstall

1. go to plugins folder, delete plugin folder redmine_auto_resubmission

`rm -r redmine_auto_resubmission`

2. restart server f.i.

`sudo /etc/init.d/apache2 restart`

### Use

#### Configuration

1. You need at least one project having the plugin added as a module. 

Goto the `Projects` -> `Settings` -> `Modules`. Select `Auto Resubmission` and save.

2. You need to have the proper privileges

Goto `Administration` -> `Roles and Permissions` -> `Select your role` -> `Select Auto Resubmission`: Check "Test resubmission-rules (x)" and "Recalculate resubmissions of all tickets (x)", the latter being very powerful.

3. Create two custom fields for issues

Goto Adminstration->Custom fields

a) create one first custom date-field and name it "Resubmission Date" (or what ever you like)   
b) create one second custom list-field and name ist "Resubmission Rule" (or what ever you like)  

4. Configure Plugin

Goto Administration->Plugins->Redmine Auto Resubmission->Configure

a) choose field for resubmission-date (the date field you have created in 3.)  
b) choose field for resubmission-rule (the rule field you have created in 3.)  
c) choose status for resubmission (this will be status, the issue is set to on resubmission)  
d) choose a line of text you want to add to a new issue journal on resubmission. Leave empty if you do not wish to add text.  

Press Apply-Button (Save)

Below the configuratiuon you can experiment with the resubmision codes. We get to that later.

5. Copy the list of resubmission codes found in the Help Text (click "Help" in the bottom of the 'Test resubmission rule' field)

6. Go back to the Custom rule-field and add these copied data to the "Possible values"-list and save.

**here the plugin should be running and work**

#### About resubmssion codes

The gist of this plugin is to tell the plugin when the issue should reappear. For that, the codes where pasted into the custom field list. If you are comfortable working with codes you can alter the rule filed to a text field and enter the codes directly. Using the preconfigured list though makes resubmission available in the issue context menu.

**What is the syntax of those codes?***

The syntax of the resubmission-rule consists of three to four parameters:
1. parameter: epoch-identifier

`D` - stands for _D_ays  
`W` - stands for _W_eeks  
`m` - stands for _m_ondays  
`M` - stands for _M_onths  
`q` - stands for _q_uarters  
`Y` - stands for _Y_ears

2. parameter: integer

`n` - stands for the number of epochs
 
3. position of day within epoch 

`F` - stands for _F_irst day of epoch, like first day of month, monday, first day of quarter, or January 1st  
`M` - stands for _M_id of epoch, like 15th day of month, wednesday, 15th of mid-of-quarter or June 30th  
`L` - stands for _L_ast of epoch, like last day of month, friday (last working day), last day of quarter or December 31st  
`W` - stands for _W_eekday (Monday), if calculated day falls on a Saturday or Sunday  
`X` - stands for no correction

3. control of date calculation

`-` - the sign "-" is a killswitch. After one date calculation the resubmission rule is deleted, so no further resubmissions happen  
`!` - the sign "!" is a force sign to force date calculation even if a resubmission date is present  
`*` - the sign "*" is a mock switch. The mock-switch is deleted from the resubmission-rule and no resubmission-date is calculated. Needed for Redmine Attribute-Quickie plugin  
     
     The control signs must be present in the above order, namely: - ! *. Any arbitrary
     subset of the control signs or all of the three control signs may be omitted.
     
Example:
`W1F`  - one week further, first day, so monday  
`M3M`  - three months further from today, mid-term, so 15th of month  
`q1-`  - next quarter, first day of quarter, so 1st Jan., Apr., Jul. or Oct., after one calculation further calculations are stopped, rule is deleted.   
`D1-`  - tomorrow, then delete rule  
`D1-!` - tomorrow!, even if a resubmission-date is present in the resubmission-date-field  
               
Resubmission dates are always calculated for the future, never for the past.  
So W0F would calculate "next monday"", if calculated on a friday, though W0 stands for this week (W0 zero weeks further, first day, monday) and would calculate last monday. 
In this case, the calculated date is advanced monday further into the future.  
So q0M would calculate "next quarter mid-term" if calculated near to lapse of current quarter. In this case the calculated date is advanced one quarter into the future.

**No I know the codes, what next?**

If you want an issue to reappear in a week from now, choose 'W1' as the resubission code. Ready! 

**Anything, I need to consider?**

Not really. But this is how the plugin works

1. If the date resubmission date field is filled with a date, then on that date the issue will reappear. On the reappearance date the resubmission code is used to calculate another resubmission date. If the resubmission code is "W1" the next resubmission is calculated and put into the date field, pretty intuitive.

2. If only the resubmission date is filled with a valid resubmission rule, then according to that rule the resubmission date is calculated. You can add a "kill-switch" (the "-" sign, see above) to the resubmission rule to calculate only one resubmission date once and not carry forward the resubmission forever.

3. If the resubmission rule contains an exclamation mark ("!") then the current resubmission date is overriden with the one according to the resubmission rule.

**Now, how is the resubmission triggered?**

There is two ways: 

a) first way is elegant, but requires cron. There is a rake task added to the plugin. In the Rails root directory type in

`export RAILS_ENV=production; rake redmine:resubmit:resubmit_issues[1]`

The above line called with cron once a day short after midnight, calculates all resubmissions. Lookup how to configure cron jobs. Be aware to properly set the RAILS_ENV variable and execute cron with the right user rights and environment for rails.

NOTE: the number [1] in squared brackets stands for the admin User-ID, which is genarally not a good idea. You MUST provide a user ID having privileges to view issues and to edit issues you want to resubmit by the rake task.
NOTE: if you specify a custom field for the resubmission rule or the resubmission date for only a ceratin role, then the user id you supply for the rake task must have privileges to actually edit these fields. 
NOTE: if you define a workflow in which the resubmission field cannot be edited then the rake task will not alter the field.

If you define the custom filed for all roles and Anonymous users can edit the field, then the rake task runs well without the ID.

b) second way is to call the following url 

`http://<your redmine host>/calc_resubmissions`

You need to have the above Recalculate-resubmissions-of-all-tickets privilege to call that url.

That's about it.

**Have fun!**

### Localizations

* German
* English

### Change-Log

1.0.7 added user edit privilege awareness

1.0.6 added support to choose between resubmitting open or all issues

1.0.5 Rails 5 / redmine 4+ support

1.0.4 never published

1.0.3 never published

1.0.2 initial commit 

1.0.1 running on redmine 3.4.6

1.0.0 running on redmine 3.3.3
