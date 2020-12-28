require 'rails_helper'
require 'webauthn/fake_client'

describe Admin::TwoFactorAuthenticationsController do
  render_views

  let(:user) { Fabricate(:user) }
  before do
    sign_in Fabricate(:user, admin: true), scope: :user
  end

  describe 'DELETE #destroy' do
    context 'when user has OTP enabled' do
      before do
        user.update(otp_required_for_login: true)
      end

      it 'redirects to admin accounts page' do
        delete :destroy, params: { user_id: user.id }

        user.reload
        expect(user.otp_enabled?).to eq false
        expect(response).to redirect_to(admin_accounts_path)
      end
    end

    context 'when user has OTP and WebAuthn enabled' do
      let(:fake_client) { WebAuthn::FakeClient.new('http://test.host') }

      before do
        user.update(otp_required_for_login: true, webauthn_id: WebAuthn.generate_user_id)

        public_key_credential = WebAuthn::Credential.from_create(fake_client.create)
        Fabricate(:webauthn_credential,
                  user_id: user.id,
                  external_id: public_key_credential.id,
                  public_key: public_key_credential.public_key,
                  nickname: 'Security Key')
      end

      it 'redirects to admin accounts page' do
        delete :destroy, params: { user_id: user.id }

        user.reload
        expect(user.otp_enabled?).to eq false
        expect(user.webauthn_enabled?).to eq false
        expect(response).to redirect_to(admin_accounts_path)
      end
    end
  end
end
