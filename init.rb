require 'redmine'
require 'base64'
require 'dispatcher'

Redmine::Plugin.register :redmine_screenshot_paste do
  name 'Screenshot Paste'
  author 'Jean-Philippe Lang'
  description 'Allow pasting a screenshot from the clipboard on the issue form.'
  version '1.0.2'
end

class UploadedScreenshot
  def initialize(content, name)
    @raw = StringIO.new(Base64.decode64(content))
    @name = name.to_s.strip
    @name = "screenshot" if @name.blank?
    @name << ".png"
  end
  
  def size
    @raw.size
  end
  
  def original_filename
    @name
  end
  
  def content_type
    "image/png"
  end
  
  def read(*args)
    @raw.read(*args)
  end
end

module RedmineScreenshotPaste
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.send(:alias_method_chain, :attach_files, :screenshot)
  end

  module InstanceMethods
    def attach_files_with_screenshot(obj, attachments)
      if screenshot = params[:uploaded_screenshot]
        file = UploadedScreenshot.new(screenshot['content'], screenshot['name'])
        attachments[:screenshot] = {:file => file,
                                    :description => screenshot['description']}
      end
      attach_files_without_screenshot(obj, attachments)
    end
  end
end


class RedmineScreenshotPasteHook < Redmine::Hook::ViewListener
  render_on :view_issues_form_details_bottom, :partial => 'screenshot'
end

Dispatcher.to_prepare :redmine_screenshot_paste do
  ApplicationController.send :include, RedmineScreenshotPaste
end
