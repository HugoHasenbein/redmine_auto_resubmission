# encoding: utf-8
#
# Redmine plugin for quick attribute setting of redmine issues
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
    module ApplicationHelperPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          
          alias_method_chain :catch_macros, :context
          
        end #base
      end #self

      module ClassMethods
      end #module

      module InstanceMethods
        
      #----------------------------------------------------------------------------------------|
       def catch_macros_with_context(text)

          #pattern = /(?<=\s|>|^):(\w{2,4})(?=$|<|\s)/
          # here, we should not match a killswitch
          pattern = /(?<=\s|>|^):([DWMYCmq]\d+[XFMLW]?)(?:,?\ ?)([^\ ^$^<^\s]*)(?=$|<|\s)/
          text.gsub!(pattern) do |m|
            # sub patterns do not work in blocks, it seems
            # therefore, we do match the match again, this time without
            # trailing and prefixing elements
            #matches = m.match(/:(\w{2,4})/)
            matches = m.match(/:([DWMYCmq]\d+[XFMLW]?)(?:,?\ ?)([^\ ^$^<^\s]*)/)
            # here we do have a match for sure, else we would not be here
            # Regexp.last_match[0] - entire match
            # Regexp.last_match[1] - rule 
            _rule   = Regexp.last_match[1]
            _format = Regexp.last_match[2]
            _args   = [_rule, _format].select(&:present?).join(",")
            #date, rule = RedmineAutoResubmission.calcfuturedate( DateTime.now, rule )          
            #date.present? ? I18n.localize(date.to_date, :format => :datemacro) : ""
            "{{date(#{_args})}}"
          end
            
          catch_macros_without_context(text)
        end #def
        
      end #module
    end #module
  end #module
end #module

unless ApplicationHelper.included_modules.include?(RedmineAutoResubmissionIssuePatch::Patches::ApplicationHelperPatch)
  ApplicationHelper.send(:include, RedmineAutoResubmissionIssuePatch::Patches::ApplicationHelperPatch)
end
