# encoding: utf-8
#
# Redmine plugin for provides a resubmission tool for issues
#
# Copyright © 2018-2020 Stephan Wenzel <stephan.wenzel@drwpatent.de>
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
          
          before_update :update_date_fields
          
          scope :hasbegun, lambda { where("#{self.table_name}.start_date < NOW()") }
          scope :overdue,  lambda { where("#{self.table_name}.due_date < NOW()")   }
          scope :with_present_custom_field, lambda { |*args| 
            joins(:custom_values).
            where("custom_values.custom_field_id = ?", args.first.to_i).
            where("custom_values.value NOT LIKE ''").
            where("custom_values.value IS NOT NULL")
          }
        end
      end
      
      
      module ClassMethods
      end #module
      
      module InstanceMethods
      
        def update_date_fields
          
          resubmission_date_field, 
          resubmission_rule_field,
          start_date_rule_field,
          due_date_rule_field = get_custom_values_for_rules
          
          ##########################################################
          # resubmission dates                                     #
          ##########################################################
          if resubmission_rule_field.present? && resubmission_date_field.present?
          
            old_rule = resubmission_rule_field.value
            
            if resubmission_date_field.value.present?
              old_date = resubmission_date_field.value
            else
              old_date = Date.today
            end
              
            new_date, new_rule = RedmineAutoResubmission::calcfuturedate( old_date, old_rule )
            resubmission_rule_field.value= new_rule                      if new_rule
            resubmission_date_field.value= new_date.strftime("%Y-%m-%d") if new_date
            @custom_field_values_changed= true                           if new_rule || new_date
          end
          
          ##########################################################
          # due_date extension (do before start date)              #
          ##########################################################
          if due_date_rule_field.present? && !read_only_attribute_names(User.current).include?('due_date')
          
            new_date, new_rule = RedmineAutoResubmission::calcfuturedate( due_date, due_date_rule_field.value )
            
            self.due_date = new_date                                     if new_date
            due_date_rule_field.value= new_rule                          if new_rule
            @custom_field_values_changed= true                           if new_rule
          end
          
          ##########################################################
          # start_date extension                                   #
          ##########################################################
          if start_date_rule_field.present? && !read_only_attribute_names(User.current).include?('start_date')
          
            new_date, new_rule = RedmineAutoResubmission::calcfuturedate( start_date, start_date_rule_field.value )
            
            if new_date.blank? || (self.due_date && new_date <= self.due_date)
            
              self.start_date = new_date                                 if new_date
              start_date_rule_field.value= new_rule                      if new_rule
              @custom_field_values_changed= true                         if new_rule
            end
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
          custom_field_ids = [
            Setting['plugin_redmine_auto_resubmission']['custom_field_id_date'],
            Setting['plugin_redmine_auto_resubmission']['custom_field_id_rule'],
            Setting['plugin_redmine_auto_resubmission']['custom_field_id_start_date_rule'],
            Setting['plugin_redmine_auto_resubmission']['custom_field_id_due_date_rule']
          ] - read_only_attribute_names(User.current)
          custom_field_ids &= editable_custom_fields(User.current).map{|cf| cf.id.to_s }
          custom_field_ids.map {|s| s.present? ? visible_custom_value_for(s) : nil }
        end #def
        
      end #module
    end
  end
end

unless Issue.included_modules.include?(RedmineAutoResubmissionIssuePatch::Patches::IssuePatch)
    Issue.send(:include, RedmineAutoResubmissionIssuePatch::Patches::IssuePatch)
end
