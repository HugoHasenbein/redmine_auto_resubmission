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

module RedmineAutoResubmissionIssuePatch
  module Patches
    module IssuePatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
        base.class_eval do
          unloadable
                     
          before_save :check_resubmission_date
        end
      end


      module ClassMethods
      end #module

      module InstanceMethods
      
        def check_resubmission_date
          @custom_field_id_date   = Setting['plugin_redmine_auto_resubmission']['custom_field_id_date']
          @custom_field_id_rule   = Setting['plugin_redmine_auto_resubmission']['custom_field_id_rule']

          if @custom_field_id_date.present? && @custom_field_id_rule.present?

			datefield     = visible_custom_field_values.select {|v| v.custom_field_id == @custom_field_id_date.to_i}.first # will have only one   
			rulefield     = visible_custom_field_values.select {|v| v.custom_field_id == @custom_field_id_rule.to_i}.first # will have only one

			if datefield.present? && rulefield.present?

			  if datefield.value.blank? && rulefield.value.present?

     			today              = DateTime.now.in_time_zone(Time.zone.name).beginning_of_day
     			rule               = rulefield.value
			    new_date, new_rule = RedmineAutoResubmission.calcfuturedate( today, rule )
			    
			    datefield.value    = new_date.present? ? new_date.strftime("%Y-%m-%d") : "" 
			    rulefield.value    = new_rule if new_rule && rulefield.value != new_rule

			  elsif datefield.value.present? && rulefield.value.present?

			    # check if rulefield shall overrule datefield
			    # override happens if rule contains "!"
     			today              = DateTime.now.in_time_zone(Time.zone.name).beginning_of_day
     			rule               = rulefield.value
			    new_date, new_rule = RedmineAutoResubmission.calcfuturedate( today, rule, :override => true )
			    
			    datefield.value    = new_date.strftime("%Y-%m-%d") if new_date.present?
			    rulefield.value    = new_rule if new_rule && rulefield.value != new_rule # careful new_rule may be empty space, which is "truthy"
			  end
			end
		  end
        end #def

      end #module
    end
  end
end

unless Issue.included_modules.include?(RedmineAutoResubmissionIssuePatch::Patches::IssuePatch)
    Issue.send(:include, RedmineAutoResubmissionIssuePatch::Patches::IssuePatch)
end
