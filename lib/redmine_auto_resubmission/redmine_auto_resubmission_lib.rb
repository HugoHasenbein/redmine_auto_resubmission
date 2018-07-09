# encoding: utf-8
#
# Redmine plugin for provides a resubmission tool for issues
#
# Copyright © 2018 Stephan Wenzel <stephan.wenzel@drwpatent.de>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

module RedmineAutoResubmission 

  def self.calc_all_resubmission_dates
  
    @issue_status_id        = Setting['plugin_redmine_auto_resubmission']['issue_status_id']
    @custom_field_id_date   = Setting['plugin_redmine_auto_resubmission']['custom_field_id_date']
    @custom_field_id_rule   = Setting['plugin_redmine_auto_resubmission']['custom_field_id_rule']
    
    @cf = CustomField.find(@custom_field_id_date)     
    
    @trackers  = @cf.trackers
    # search issues having a concrete resubmission date
    @issues    =    Issue.
      where(:tracker_id => @trackers).
      joins("INNER JOIN custom_values ON custom_values.customized_id = issues.id").
      where("custom_values.customized_type LIKE 'Issue'").
      where("custom_values.custom_field_id IN (#{@custom_field_id_date}, #{@custom_field_id_rule})").
      where("custom_values.value NOT LIKE ''").
      distinct.
      to_a
      
    calc_resubmission_dates( @issues )
  end #def
  
  # ----------------------------------------------------------------------------------- #
  def self.calc_resubmission_dates( issues )
  
                    
    issues.each do |issue|

      datefield     = issue.custom_field_values.select {|v| v.custom_field_id == @custom_field_id_date.to_i}.first # will have only one   
      rulefield     = issue.custom_field_values.select {|v| v.custom_field_id == @custom_field_id_rule.to_i}.first # will have only one
      new_journal   = Journal.new(:journalized => issue, :user => User.current || User.anonymous )      
                                                  
      begin
        date = datefield.value.in_time_zone(Time.zone.name)
      rescue
        date = nil
      end
      today         = Date.today
      #today         = DateTime.now.in_time_zone(Time.zone.name).beginning_of_day
      new_date      = date
      new_rule      = rulefield.value
      new_status_id = issue.status_id
      resubmitted   = false
      

      if date.blank?
        # blank date or faulty date string => calculate first resubmission date
        # rule must be present, due to the SQL stement  
        new_date, new_rule  = calcfuturedate( today, rulefield.value )     
      end #if
      
      if (date.present? && (today >= date))     
        # today is newer than date or equal  => resubmit
        if rulefield.value.present? 
          # calculate next resubmission for recurring resubmission
          new_date, new_rule    = calcfuturedate( date, rulefield.value ) 
        else
          # delete date - this is only this one resubmission
          new_date  = nil
        end
        
        new_status_id   = @issue_status_id 
        resubmitted     = true

      end # if
      
      # --- keep changes of issue status --- #
      if (issue.status_id.to_i != new_status_id.to_i)
        new_journal.details << JournalDetail.new(:property  => 'attr', 
                                                 :prop_key  => "status_id", 
                                                 :old_value => issue.status_id, 
                                                 :value     => new_status_id 
                                                )
        issue.status_id = new_status_id.to_i
      end #if

      # --- keep changes of resubmission date --- #
      if new_date != date
        new_journal.details << JournalDetail.new(:property  => 'cf', 
                                                 :prop_key  => datefield.custom_field_id, 
                                                 :old_value     => datefield.value, 
                                                 :value         => new_date.present? ? new_date.strftime("%Y-%m-%d") : ""
                                                ) 
        datefield.value     = new_date.present? ? new_date.strftime("%Y-%m-%d") : ""    
      end #if
                                              
      # --- keep changes of resubmission rule --- #
      if rulefield.value != new_rule
        new_journal.details << JournalDetail.new(:property  => 'cf', 
                                                 :prop_key  => rulefield.custom_field_id, 
                                                 :old_value     => rulefield.value, 
                                                 :value         => new_rule 
                                                ) 
        rulefield.value     = new_rule
      end #if
      
      # --- post message --- #
      if resubmitted && Setting['plugin_redmine_auto_resubmission']['resubmission_notice'].present?
        new_journal.notes = Setting['plugin_redmine_auto_resubmission']['resubmission_notice']
      end #if

      if new_journal.details.any? || resubmitted
        issue.touch # mark as updated
        issue.save! # saves journals 
        new_journal.save!
      end
      
    end #each
    
    issues.length
    
  end #def



  # ----------------------------------------------------------------------------------- #
  def self.calcfuturedate( startdate, rule, options = {} )
    
    if rule.present?
    
      matches = /([DWMYCmq])([0-9]+)([XFMLW]?)(-?)(!?)(\*?)(.*)/.match(rule)
    
      epoch, num, pos, killswitch, force, mockswitch, trailing_rest = matches.present? ? matches.captures : ["", "", "", "", "", "", ""]

      if mockswitch.present?
      
        # mockswitch does not calculate anything
        # mockswitch is removed, however
        new_date = nil
        new_rule = "#{epoch}#{num}#{pos}#{killswitch}#{force}#{trailing_rest}"
        
      elsif ( epoch.present? && num.present? )
      
        if options[:override].present?
        
		  # "!" overrides date by force
		  if force.present?
            new_date = advance_date( startdate, epoch, num ) 
            new_date = adjust_date(  new_date,  epoch, pos ) 
			new_rule = nil
		  else
		    # override protection: do not recalculate
		    # returning nil means: do not change 
			new_date = nil
            new_rule = nil
		  end #if
		  
        else # no override (normal case)
          new_date = advance_date( startdate, epoch, num ) 
          new_date = adjust_date(  new_date,  epoch, pos ) 
        
		  if killswitch.present?
			new_rule = ""
		  else
			new_rule = rule
		  end #if
        
        end
        
      else # epoch an num is not present: do not calculate date
        new_date = startdate
        new_rule = rule
      end #if
      
    else # no rule is present: do not calculate
      new_date = startdate
      new_rule = rule
    end #if
    
    [new_date, new_rule]
  end #def

  # ----------------------------------------------------------------------------------- #
  # calculate n times advance of epoch
  # epoch: D - n days
  # epoch: W - n weeks
  # epoch: M - n months
  # epoch: Y - n years
  #
  # epoch: C - n calendar weeks
  # epoch: m - n mondays
  # epoch: q - q quarters
  
  def self.advance_date( startdate, epoch, num )
  
    today = DateTime.now.in_time_zone(Time.zone.name).beginning_of_day
		  
    case epoch  
      when "D"
          new_date = startdate.advance( :days => num.to_i)        
      when "W"
          new_date = startdate.advance( :weeks => num.to_i)
      when "M"
          new_date = startdate.advance( :months => num.to_i)
      when "Y"
          new_date = startdate.advance( :years => num.to_i)
      when "m"
          new_date = startdate.advance( :weeks => num.to_i).monday 
          #new_date = startdate.advance( :weeks => (num.to_i+1)).monday if new_date <= today 
      when "q"
          new_date = startdate.advance( :months => 3 * num.to_i).beginning_of_quarter
          #new_date = startdate.advance( :months => 3 * (num.to_i+1)).beginning_of_quarter if new_date <= today 
	  when "C"
		  # calendar week 1 is the week containing Jan. 4th
		  new_date = DateTime.new(startdate.year, 1, 4).advance( :weeks => (num.to_i - 1))
		  #new_date = DateTime.new(startdate.year+1, 1, 4).advance( :weeks => (num.to_i - 1)) if new_date <= today
      else
          new_date = startdate
    end #case
    
    new_date 
    
  end #def

  # ----------------------------------------------------------------------------------- #
  # calculate time adjustment of epoch (_F_irst, _M_id, _L_ast, _W_orking day)
  # epoch: W - week:  F - Monday, M - Wednesday, L - Friday, W - Monday
  # epoch: M - month: F - 1st,    M - 15th,      L - last, W - Monday
  # epoch: Y - year:  F - 01/01,  M - 06/30,     L - 12/31, W - Monday
  # epoch: q - quarter:  W - Monday

  def self.adjust_date( startdate, epoch, pos )
  
  	today = DateTime.now.in_time_zone(Time.zone.name).beginning_of_day

    case epoch
      when "D"
        case pos
          when "W"
          # if saturday or sunday, fall back to last monday, then add one week for monday coming up
            (startdate.wday % 6) != 0 ? new_date = startdate : new_date = startdate.monday.advance(:days => 7)
          else
            new_date = startdate
        end #case

      when "W", "C"
        # week
        case pos
          when "F"
            # Monday
            new_date = startdate.monday
            new_date = startdate.advance( :weeks => 1).monday if new_date <= today

          when "M"
            # Wednesday = Monday + 2 days
            new_date = startdate.monday.advance(:days => 2)
            new_date = startdate.advance( :weeks => 1).monday.advance(:days => 2) if new_date <= today
          when "L"
            # Friday = Monday + 4 days
            new_date = startdate.monday.advance(:days => 4)
            new_date = startdate.advance( :weeks => 1).monday.advance(:days => 4) if new_date <= today
          when "W"
          # if saturday or sunday, fall back to last monday, then add one week for monday coming up
            (startdate.wday % 6) != 0 ? new_date = startdate : new_date = startdate.monday.advance(:days => 7)
          else
            new_date = startdate
        end #case
      
      when "M"
        # month
        case pos
          when "F"
            # 1st
            new_date = startdate.beginning_of_month
            new_date = startdate.advance( :months => 1).beginning_of_month if new_date <= today
          when "M"
            # 15th 
            new_date = startdate.beginning_of_month.advance(:days => 14)
            new_date = startdate.advance( :months => 1).beginning_of_month.advance(:days => 14) if new_date <= today
          when "L"
            # last day
            new_date = startdate.end_of_month
            #new_date = startdate.advance( :months => 1).end_of_month if new_date <= today
          when "W"
          # if saturday or sunday, fall back to last monday, then add one week for monday coming up
            (startdate.wday % 6) != 0 ? new_date = startdate : new_date = startdate.monday.advance(:days => 7)
          else
            new_date = startdate
        end #case
       
      when "Y"
        # year
        case pos
          when "F"
            # Jan. 1st
            new_date = startdate.beginning_of_year
            new_date = startdate.advanve(:years => 1).beginning_of_year if new_date <= today
          when "M"
            # Jun. 30th 
            new_date = startdate.
                        beginning_of_year.
                        advance(:months => 5).
                        advance(:days => 29)
            new_date = startdate.
                        advance(:years => 1).
                        beginning_of_year.
                        advance(:months => 5).
                        advance(:days => 29) if new_date <= today
          when "L"
            # Dec. 31st
            new_date = startdate.
                        beginning_of_year.
                        advance(:months => 11).
                        advance(:days => 30)
          when "W"
          # if saturday or sunday, fall back to last monday, then add one week for monday coming up
            (startdate.wday % 6) != 0 ? new_date = startdate : new_date = startdate.monday.advance(:days => 7)
          else
            new_date = startdate
        end #case

      when "q"
        case pos
          when "F"
            # Jan. 1st
            new_date = startdate.beginning_of_quarter
            new_date = startdate.advance( :months => 3).beginning_of_quarter if new_date <= today 
          when "M"
            # Jun. 30th 
            new_date = startdate.
                        beginning_of_quarter.
                        advance(:months => 1).
                        advance(:days => 15)
            new_date = startdate.
                        advance(:quarters => 1).
                        beginning_of_quarter.
                        advance(:months => 1).
                        advance(:days => 15) if new_date <= today
          when "L"
            # Dec. 31st
            new_date = startdate.end_of_quarter
          when "W"
          # if saturday or sunday, fall back to last monday, then add one week for monday coming up
            (startdate.wday % 6) != 0 ? new_date = startdate : new_date = startdate.monday.advance(:days => 7)
          else
            new_date = startdate
        end #case
        
      else
        new_date = startdate
    end #case epoch

    new_date > today ? new_date : startdate
    
  end #def  


  
  # ----------------------------------------------------------------------------------- #
end #class
