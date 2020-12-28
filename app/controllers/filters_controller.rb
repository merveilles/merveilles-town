# frozen_string_literal: true

class FiltersController < ApplicationController
  layout 'admin'

  before_action :authenticate_user!
  before_action :set_filters, only: :index
  before_action :set_filter, only: [:edit, :update, :destroy]
  before_action :set_body_classes

  def index
    @filters = current_account.custom_filters.order(:phrase)
  end

  def new
    @filter = current_account.custom_filters.build
  end

  def create
    @filter = current_account.custom_filters.build(resource_params)

    if @filter.save
      redirect_to filters_path
    else
      render action: :new
    end
  end

  def edit; end

  def update
    if @filter.update(resource_params)
      redirect_to filters_path
    else
      render action: :edit
    end
  end

  def destroy
    @filter.destroy
    redirect_to filters_path
  end

  private

  def set_filters
    @filters = current_account.custom_filters
  end

  def set_filter
    @filter = current_account.custom_filters.find(params[:id])
  end

  def resource_params
    params.require(:custom_filter).permit(:phrase, :expires_in, :irreversible, :whole_word, context: [])
  end

  def set_body_classes
    @body_classes = 'admin'
  end
end
