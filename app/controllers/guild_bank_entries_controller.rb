# frozen_string_literal: true

class GuildBankEntriesController < ApplicationController
  before_action :set_guild

  def index
    authorize @guild, :show?
    @entries = @guild.guild_bank_entries.order(created_at: :desc).includes(:actor)
    @guild_bank_entry = @guild.guild_bank_entries.new
  end

  def create
    membership = current_user.guild_memberships.find_by(guild: @guild)
    Guilds::PermissionService.new(membership:).ensure!(:manage_bank)

    @guild_bank_entry = @guild.guild_bank_entries.new(guild_bank_entry_params.merge(actor: current_user))
    authorize @guild_bank_entry

    GuildBankEntry.transaction do
      @guild_bank_entry.save!
      @guild.update_treasury!(@guild_bank_entry.currency_type.to_sym, @guild_bank_entry.amount)
    end

    redirect_to guild_guild_bank_entries_path(@guild), notice: "Guild bank updated."
  rescue ActiveRecord::RecordInvalid => e
    @entries = @guild.guild_bank_entries.order(created_at: :desc)
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :index, status: :unprocessable_entity
  end

  private

  def set_guild
    @guild = Guild.find(params[:guild_id])
  end

  def guild_bank_entry_params
    params.require(:guild_bank_entry).permit(:entry_type, :currency_type, :amount, :notes)
  end
end
