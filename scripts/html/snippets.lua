--[[
  Mitchell's html/snippets.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- Snippets for the html module
module('modules.html.snippets', package.seeall)

if not _G.snippets then _G.snippets = {} end
local snippets = _G.snippets

snippets.none = {
  t   = '<${1:p}>${0}</${1/^\\s*(\\S+)\\s*/$1/}>',
  d   = '<div>${0}</div>',
  dc  = '<div class="${1:class}">${0}</div>',
  ds  = '<div style="${1:style}">${0}</div>',
  p   = '<p>${0}</p>',
  pc  = '<p class="${1:class}">${0}</p>',
  ps  = '<p style="${1:style}">${0}</p>',
  s   = '<span>${0}</span>',
  sc  = '<span class="${1:class}">${0}</span>',
  ss  = '<span style="${1:style}">${0}</span>',
  a   = '<a href="${1:url}">${0}</a>',
  an  = '<a name="${1:anchor}">${0}</a>',
  img = '<img src="${1:url}" alt="${2:alt_text}"${3: width="${4:}" height="${5:}"} />',
  nb  = '&nbsp;',
  f   = '<form action="${1:url}" method="${2:post}" name="${3:}"${4:id="${5:${2}}"}>\n  ${0}\n</form>',
  res = '<input type="reset" name="${1:}"${2: id="${3:${1}}"} value="${4:button_text}" />',
  sub = '<input type="submit" name="${1:}"${2: id="${3:${1}}"} value="${4:button_text}" />',
  che = '<input type="checkbox" name="${1:}"${2: id="${3:${1}}"} value="${4:${1}}"${5: checked="checked"} />',
  file = '<input type="file" name="${1:}"${2: id="${3:${1}}"} accept="${4:mime_types}" />',
  hid = '<input type="hidden" name="${1:}"${2: id="${3:${1}}"} value="${4:default_value}" />',
  pas = '<input type="password" name="${1:}"${2: id="${3:${1}}"} value="${4:default_value}" />',
  rad = '<input type="radio" name="${1:}"${2: id="${3:${1}}"} value="${4:default_value}"${5: checked="checked"} />',
  tex = '<input type="text" name="${1:}"${2: id="${3:${1}}"} value="${4:default_value}" />',
  ['in'] = '<input type="${1:}" name="${2:}"${3: id="${4:${2}}"} value="${5:}" />',
  lab = '<label for="${1:input_item_id}">${2:Label Text}</label>',
  optg = '<optgroup label="${1:label}">\n  ${0}\n</optgroup>',
  opt = '<option label="${1:label}" value="${2:value}"${3: selected="selected"}>${0}</option>',
  sel = '<select name="${1:}" id="${2:${1}}" size="${3:}"${4: multiple="multiple"}>\n  ${0}\n</select>',
  texa = '<textarea name="${1:}" id="${2:${1}}" rows="${3:}" cols="${4:}">${0}</textarea>',
  fs  = '<fieldset>\n  <legend>${1:}</legend>\n  ${0}\n</fieldset>',
  base = '<base href="${1:}"${2: target="${3:}"} />',
  lin = '<link rel="${1:stylesheet}" type="${2:text/css}" href="${3:style.css}"${4: media="${5:screen}"} />',
  met = '<meta name="${1:name}" content="${2:content}" />',
  strict = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n  \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n\n",
  html =
[[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    ${1:}

    <title>${2:title}</title>
  </head>
  <body>
    ${0}
  </body>
</html>]]
}

-- rails snippets
if props['FileExt'] == 'rhtml' then
  snippets.none.r   = "<% ${0} %>"
  snippets.none.re  = "<%= ${0} %>"
  snippets.none.is  = "=> "
  snippets.none.mac = "add_column '${1:table}', '${2:column}', :${3:string}"
  snippets.none.mcc = "t.column '${1:title}', :${2:string}"
  snippets.none.mct = "create_table '${1:table}' do |t|\n  ${0}\nend"
  snippets.none.mdt = "drop_table '${1:table}'"
  snippets.none.mrc = "remove_column '${1:table}', '${2:column}'"
  snippets.none.rdb = "RAILS_DEFAULT_LOGGER.debuf \"${1:message}\""
  snippets.none.bt  = "belongs_to :${1:object}${2:, :class_name => '${3:ClassName}', :foreign_key => '${4:${1}_id}'}"
  snippets.none.hbm = "has_and_belongs_to_many :${1:object}${2:, :join_table => '${3:table_name}', :foreign_key => '${4:${1}_id}'}"
  snippets.none.hm  = "has_many :${1:object}${2:, :class_name => '${3:ClassName}', :foreign_key => '${4:${1}_id}'}"
  snippets.none.ho  = "has_one :${1:object}${2:, :class_name => '${3:ClassName}', :foreign_key => '${4:${1}_id}'}"
  snippets.none.lia   = "<%= link_to '${1:link text...}', :action => '${2:index}' %>"
  snippets.none.liai  = "<%= link_to '${1:link text...}', :action => '${2:edit}', :id => ${3:@item} %>"
  snippets.none.lic   = "<%= link_to '${1:link text...}', :controller => '${2:items}' %>"
  snippets.none.lica  = "<%= link_to '${1:link text...}', :controller => '${2:items}', :action => '${3:index}' %>"
  snippets.none.licai = "<%= link_to '${1:link text...}', :controller => '${2:items}', :action => '${3:edit}', :id => ${4:@item} %>"
  snippets.none.ldb   = "logger.debug \"${1:message}\""
  snippets.none.fla   = "flash[:${1:notice}] = \"${2:Successfully created...}\""
  snippets.none.logi  = "logger.info \"${1:Current value is...}\""
  snippets.none.par   = "params[:${1:id}]"
  snippets.none.ses   = "session[:${1:user}]"
  snippets.none.rcea  = "render_component :action => '${1:index}'"
  snippets.none.rcec  = "render_component :controller => '${1:items}'"
  snippets.none.rceca = "render_component :controller => '${1:items}', :action => '${2:index}'"
  snippets.none.rea   = "redirect_to :action => '${1:index}'"
  snippets.none.reai  = "redirect_to :action => '${1:show}', :id => ${2:@item}"
  snippets.none.rec   = "redirect_to :controller => '${1:items}'"
  snippets.none.reca  = "redirect_to :controller => '${1:items}', :action => '${2:list}'"
  snippets.none.recai = "redirect_to :controller => '${1:items}', :action => '${2:show}', :id => ${3:@item}"
  snippets.none.ra   = "render :action => '${1:action}'"
  snippets.none.ral  = "render :action => '${1:action}', :layout => '${2:layoutname}'"
  snippets.none.rf   = "render :file => '${1:filepath}'"
  snippets.none.rfu  = "render :file => '${1:filepath}', :use_full_path => ${2:false}"
  snippets.none.ri   = "render :inline => '${1:<%= 'hello' %>}'"
  snippets.none.ril  = "render :inline => '${1:<%= 'hello' %>}', :locals => { ${2::name} => '${3:value}'$4 }"
  snippets.none.rit  = "render :inline => '${1:<%= 'hello' %>}', :type => ${2::rxml}"
  snippets.none.rl   = "render :layout => '${1:layoutname}'"
  snippets.none.rn   = "render :nothing => ${1:true}"
  snippets.none.rns  = "render :nothing => ${1:true}, :status => ${2:401}"
  snippets.none.rp   = "render :partial => '${1:item}'"
  snippets.none.rpc  = "render :partial => '${1:item}', :collection => ${2:items}"
  snippets.none.rpl  = "render :partial => '${1:item}', :locals => { :${2:name} => '${3:value}'$4 }"
  snippets.none.rpo  = "render :partial => '${1:item}', :object => ${2:object}"
  snippets.none.rps  = "render :partial => '${1:item}', :status => ${2:500}"
  snippets.none.rt   = "render :text => \"${1:text to render...}\""
  snippets.none.rtl  = "render :text => \"${1:text to render...}\", :layout => '${2:layoutname}'"
  snippets.none.rtlt = "render :text => \"${1:text to render...}\", :layout => ${2:true}"
  snippets.none.rts  = "render :text => \"${1:text to render...}\", :status => ${2:401}"
  snippets.none.va   = "validates_associated :${1:attribute}${2:, :on => :${3:create}}"
  snippets.none.vaif = "validates_associated :${1:attribute}${2:, :on => :${3:create}, :if => proc { |obj| ${5:obj.condition?} }}"
  snippets.none.vc   = "validates_confirmation_of :${1:attribute}${2:, :on => :${3:create}, :message => \"${4:should match confirmation}\"}"
  snippets.none.vcif = "validates_confirmation_of :${1:attribute}${2:, :on => :${3:create}, :message => \"${4:should match confirmation}\", :if => proc { |obj| ${5:obj.condition?} }}"
  snippets.none.ve   = "validates_exclusion_of :${1:attribute}${2:, :in => ${3:enumerable}, :on => :${4:create}, :message => \"${5:is not allowed}\"}"
  snippets.none.veif = "validates_exclusion_of :${1:attribute}${2:, :in => ${3:enumerable}, :on => :${4:create}, :message => \"${5:is not allowed}\", :if => proc { |obj| ${6:obj.condition?} }}"
  snippets.none.vl   = "validates_length_of :${1:attribute}, :within => ${2:3..20}${3:, :on => :${4:create}, :message => \"${5:must be present}\"}"
  snippets.none.vp   = "validates_presence_of :${1:attribute}${2:, :on => :${3:create}, :message => \"${4:can't be blank}\"}"
  snippets.none.vpif = "validates_presence_of :${1:attribute}${2:, :on => :${3:create}, :message => \"${4:can't be blank}\"}, :if => proc { |obj| ${5:obj.condition?} }}"
  snippets.none.vu   = "validates_uniqueness_of :${1:attribute}${2:, :on => :${3:create}, :message => \"${4:must be unique}\"}"
  snippets.none.vuif = "validates_uniqueness_of :${1:attribute}${2:, :on => :${3:create}, :message => \"${4:must be unique}\", :if => proc { |obj| ${6:obj.condition?} }}"
end

-- zope dtml snippets
if props['FileExt'] == 'dtml' then
  snippets.none['if'] = "<dtml-if ${1:}>${0}</dtml-if>"
  snippets.none['else'] = "<dtml-else>"
  snippets.none.var   = "<dtml-var ${1:name}>"
  snippets.none.call  = "<dtml-call ${0}>"
  snippets.none.let   = "<dtml-let ${1:var}=\"${2:value}\">${0}</dtml-let>"
  snippets.none.com   = "<dtml-comment>${0}</dtml-comment>"
end
