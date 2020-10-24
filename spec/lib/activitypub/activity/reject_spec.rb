require 'rails_helper'

RSpec.describe ActivityPub::Activity::Reject do
  let(:sender)    { Fabricate(:account) }
  let(:recipient) { Fabricate(:account) }
  let(:object_json) do
    {
      id: 'bar',
      type: 'Follow',
      actor: ActivityPub::TagManager.instance.uri_for(recipient),
      object: ActivityPub::TagManager.instance.uri_for(sender),
    }
  end

  let(:json) do
    {
      '@context': 'https://www.w3.org/ns/activitystreams',
      id: 'foo',
      type: 'Reject',
      actor: ActivityPub::TagManager.instance.uri_for(sender),
      object: object_json,
    }.with_indifferent_access
  end

  describe '#perform' do
    subject { described_class.new(json, sender) }

    context 'rejecting a pending follow request by target' do
      before do
        Fabricate(:follow_request, account: recipient, target_account: sender)
        subject.perform
      end

      it 'does not create a follow relationship' do
        expect(recipient.following?(sender)).to be false
      end

      it 'removes the follow request' do
        expect(recipient.requested?(sender)).to be false
      end
    end

    context 'rejecting a pending follow request by uri' do
      before do
        Fabricate(:follow_request, account: recipient, target_account: sender, uri: 'bar')
        subject.perform
      end

      it 'does not create a follow relationship' do
        expect(recipient.following?(sender)).to be false
      end

      it 'removes the follow request' do
        expect(recipient.requested?(sender)).to be false
      end
    end

    context 'rejecting a pending follow request by uri only' do
      let(:object_json) { 'bar' }

      before do
        Fabricate(:follow_request, account: recipient, target_account: sender, uri: 'bar')
        subject.perform
      end

      it 'does not create a follow relationship' do
        expect(recipient.following?(sender)).to be false
      end

      it 'removes the follow request' do
        expect(recipient.requested?(sender)).to be false
      end
    end

    context 'rejecting an existing follow relationship by target' do
      before do
        Fabricate(:follow, account: recipient, target_account: sender)
        subject.perform
      end

      it 'removes the follow relationship' do
        expect(recipient.following?(sender)).to be false
      end

      it 'does not create a follow request' do
        expect(recipient.requested?(sender)).to be false
      end
    end

    context 'rejecting an existing follow relationship by uri' do
      before do
        Fabricate(:follow, account: recipient, target_account: sender, uri: 'bar')
        subject.perform
      end

      it 'removes the follow relationship' do
        expect(recipient.following?(sender)).to be false
      end

      it 'does not create a follow request' do
        expect(recipient.requested?(sender)).to be false
      end
    end

    context 'rejecting an existing follow relationship by uri only' do
      let(:object_json) { 'bar' }

      before do
        Fabricate(:follow, account: recipient, target_account: sender, uri: 'bar')
        subject.perform
      end

      it 'removes the follow relationship' do
        expect(recipient.following?(sender)).to be false
      end

      it 'does not create a follow request' do
        expect(recipient.requested?(sender)).to be false
      end
    end
  end

  context 'given a relay' do
    let!(:relay) { Fabricate(:relay, state: :pending, follow_activity_id: 'https://abc-123/456') }

    let(:json) do
      {
        '@context': 'https://www.w3.org/ns/activitystreams',
        id: 'foo',
        type: 'Reject',
        actor: ActivityPub::TagManager.instance.uri_for(sender),
        object: {
          id: 'https://abc-123/456',
          type: 'Follow',
          actor: ActivityPub::TagManager.instance.uri_for(recipient),
          object: ActivityPub::TagManager.instance.uri_for(sender),
        },
      }.with_indifferent_access
    end

    subject { described_class.new(json, sender) }

    it 'marks the relay as rejected' do
      subject.perform
      expect(relay.reload.rejected?).to be true
    end
  end
end
