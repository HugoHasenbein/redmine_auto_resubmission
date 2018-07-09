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

require 'i18n'

module RedmineAutoResubmission
  module WikiMacros
  
	Redmine::WikiFormatting::Macros.register do

		desc "calculate date and return a string, {{date(W1)}} would produce a date one week from now" 
		macro :date do |obj, args|
		  _rule   = args[0].presence || "D0"
		  _format = args[1].presence || "datemacro"
		  new_date, new_rule = RedmineAutoResubmission.calcfuturedate( Date.today, _rule )
		  new_date.blank? ? "????-??-??" : I18n.localize(new_date, format: _format.to_sym) rescue I18n.localize(new_date, format: :datemacro)
		end #macro

	end #register
	
  end #module
end #module
