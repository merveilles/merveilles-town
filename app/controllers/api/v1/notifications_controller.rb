# frozen_string_literal: true

class Api::V1::NotificationsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:notifications' }, except: [:clear, :dismiss]
  before_action -> { doorkeeper_authorize! :write, :'write:notifications' }, only: [:clear, :dismiss]
  before_action :require_user!
  after_action :insert_pagination_headers, only: :index

  DEFAULT_NOTIFICATIONS_LIMIT = 15

  def index
    @notifications = load_notifications
    render json: @notifications, each_serializer: REST::NotificationSerializer, relationships: StatusRelationshipsPresenter.new(target_statuses_from_notifications, current_user&.account_id)
  end

  def show
    @notification = current_account.notifications.without_suspended.find(params[:id])
    render json: @notification, serializer: REST::NotificationSerializer
  end

  def clear
    current_account.notifications.delete_all
    render_empty
  end

  def dismiss
    current_account.notifications.find_by!(id: params[:id]).destroy!
    render_empty
  end

  private

  def load_notifications
    cache_collection_paginated_by_id(
      browserable_account_notifications,
      Notification,
      limit_param(DEFAULT_NOTIFICATIONS_LIMIT),
      params_slice(:max_id, :since_id, :min_id)
    )
  end

  def browserable_account_notifications
    current_account.notifications.without_suspended.browserable(exclude_types, from_account)
  end

  def target_statuses_from_notifications
    @notifications.reject { |notification| notification.target_status.nil? }.map(&:target_status)
  end

  def insert_pagination_headers
    set_pagination_headers(next_path, prev_path)
  end

  def next_path
    unless @notifications.empty?
      api_v1_notifications_url pagination_params(max_id: pagination_max_id)
    end
  end

  def prev_path
    unless @notifications.empty?
      api_v1_notifications_url pagination_params(min_id: pagination_since_id)
    end
  end

  def pagination_max_id
    @notifications.last.id
  end

  def pagination_since_id
    @notifications.first.id
  end

  def exclude_types
    val = params.permit(exclude_types: [])[:exclude_types] || []
    val = [val] unless val.is_a?(Enumerable)
    val
  end

  def from_account
    params[:account_id]
  end

  def pagination_params(core_params)
    params.slice(:limit, :exclude_types).permit(:limit, exclude_types: []).merge(core_params)
  end
end
