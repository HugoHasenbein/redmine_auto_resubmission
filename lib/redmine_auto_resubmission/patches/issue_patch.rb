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
          
          before_save :update_date_fields
        end
      end
      
      
      module ClassMethods
      end #module
      
      module InstanceMethods
      
        def update_date_fields
          
          resubmission_date, 
          resubmission_rule,
          start_date_rule,
          due_date_rule = get_custom_values_for_rules
          
          ##########################################################
          # resubmission dates                                     #
          ##########################################################
          if resubmission_rule && resubmission_date
          
            new_date, new_rule = RedmineAutoResubmission::calcfuturedate( resubmission_date.value, resubmission_rule.value )
            
            resubmission_rule.value= new_rule                      if new_rule
            resubmission_date.value= new_date.strftime("%Y-%m-%d") if new_date
            @custom_field_values_changed= true                     if new_rule || new_date
          end
          
          ##########################################################
          # due_date extension (do before start date)              #
          ##########################################################
          if due_date_rule.present?
          
            new_date, new_rule = RedmineAutoResubmission::calcfuturedate( due_date, due_date_rule.value )
            
            self.due_date = new_date                               if new_date
            due_date_rule.value= new_rule                          if new_rule
            @custom_field_values_changed= true                     if new_rule
          end
          
          ##########################################################
          # start_date extension                                   #
          ##########################################################
          if start_date_rule.present?
          
            new_date, new_rule = RedmineAutoResubmission::calcfuturedate( start_date, start_date_rule.value )
            
            self.start_date = new_date                             if new_date
            start_date_rule.value= new_rule                        if new_rule
            @custom_field_values_changed= true                     if new_rule
          end
          
          return true # always return true to not cause save validation errors
          
        end #def
        
        #
        #
        #
        def visible_custom_value_for(c)
          field_id = (c.is_a?(CustomField) ? c.id : c.to_i)
          cf_value = visible_custom_field_values.detect {|v| v.custom_field_id == field_id }
        end
        
        #
        #
        #
        def get_custom_values_for_rules
          [
            Setting['plugin_redmine_auto_resubmission']['custom_field_id_date'],
            Setting['plugin_redmine_auto_resubmission']['custom_field_id_rule'],
            Setting['plugin_redmine_auto_resubmission']['custom_field_id_start_date_rule'],
            Setting['plugin_redmine_auto_resubmission']['custom_field_id_due_date_rule']
          ].map {|s| s.present? ? visible_custom_value_for(s) : nil }
        end #def
        
      end #module
    end
  end
end

unless Issue.included_modules.include?(RedmineAutoResubmissionIssuePatch::Patches::IssuePatch)
    Issue.send(:include, RedmineAutoResubmissionIssuePatch::Patches::IssuePatch)
end
