# frozen_string_literal: true

class HomeController < ApplicationController
  before_action :redirect_unauthenticated_to_permalinks!
  before_action :authenticate_user!
  before_action :set_referrer_policy_header

  def index
    @body_classes = 'app-body'
  end

  private

  def redirect_unauthenticated_to_permalinks!
    return if user_signed_in?

    matches = request.path.match(/\A\/web\/(statuses|accounts)\/([\d]+)\z/)

    if matches
      case matches[1]
      when 'statuses'
        status = Status.find_by(id: matches[2])

        if status&.distributable?
          redirect_to(ActivityPub::TagManager.instance.url_for(status))
          return
        end
      when 'accounts'
        account = Account.find_by(id: matches[2])

        if account
          redirect_to(ActivityPub::TagManager.instance.url_for(account))
          return
        end
      end
    end

    matches = request.path.match(%r{\A/web/timelines/tag/(?<tag>.+)\z})

    redirect_to(matches ? tag_path(CGI.unescape(matches[:tag])) : default_redirect_path)
  end

  def default_redirect_path
    if request.path.start_with?('/web') || whitelist_mode?
      new_user_session_path
    elsif single_user_mode?
      short_account_path(Account.local.without_suspended.where('id > 0').first)
    else
      about_path
    end
  end

  def set_referrer_policy_header
    response.headers['Referrer-Policy'] = 'origin'
  end
end
