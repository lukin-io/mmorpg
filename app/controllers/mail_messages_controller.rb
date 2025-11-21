# frozen_string_literal: true

class MailMessagesController < ApplicationController
  def index
    current_user.ensure_social_features!
    scope = policy_scope(MailMessage)
    @inbox_messages = scope.where(recipient: current_user).order(delivered_at: :desc)
    @sent_messages = scope.where(sender: current_user).order(delivered_at: :desc)
  end

  def show
    @mail_message = policy_scope(MailMessage).find(params[:id])
    authorize @mail_message

    if @mail_message.recipient == current_user && !@mail_message.read?
      @mail_message.mark_read!
    end
  end

  def new
    current_user.ensure_social_features!
    @mail_message = MailMessage.new
  end

  def create
    current_user.ensure_social_features!
    @mail_message = current_user.mail_messages.new(mail_message_params.except(:recipient_email))
    @mail_message.recipient = User.find_by!(email: mail_message_params[:recipient_email])
    authorize @mail_message

    if @mail_message.save
      redirect_to mail_messages_path, notice: "Mail sent."
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    @mail_message.errors.add(:recipient, "not found")
    render :new, status: :unprocessable_entity
  end

  private

  def mail_message_params
    params.require(:mail_message).permit(:recipient_email, :subject, :body)
  end
end
