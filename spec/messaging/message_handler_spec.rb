require 'spec_helper'

describe FBPi::MessageHandler do
  let(:bot) { FakeBot.new }
  let(:mesh) { FakeMesh.new }
  let(:message) do
    { 'fromUuid' => '1234567890',
      'method'   => 'test_message'  }
  end
  let(:handler) { FBPi::MessageHandler.new(message, bot, mesh) }

  it 'initializes' do
    expect(handler.bot).to eq(bot)
    expect(handler.mesh).to eq(mesh)
    expect(handler.message).to be_kind_of(FBPi::MeshMessage)
    expect(handler.message.from).to eq('1234567890')
    expect(handler.message.method).to eq('test_message')
    expect(handler.message.params).to eq({})
  end

  it 'Calls itself when provided a bot, message and mesh network' do
    hndlr = FBPi::MessageHandler.call(message, bot, mesh)
    msgs  = mesh.all
    expect(msgs.count).to eq(1)
    expect(msgs.first.type).to eq('error')
  end

  it 'sends errors' do
    begin
      raise 'Fake error for testing'
    rescue => fake_error
      handler.send_error(fake_error)
      expect(mesh.last.params[:error])
        .to include('Fake error for testing @ /')
    end
  end

  it 'catches errors' do
    class BadController < FBPi::AbstractController
      def call
        raise 'a fake error'
      end
    end
    FBPi::MessageHandler.add_controller('bad')

    message['method'] = 'bad'
    hndlr = FBPi::MessageHandler.call(message, bot, mesh)
    msg = mesh.all.first.params[:error]
    expect(msg).to include('a fake error')
  end

  it 'politely tells you why your controller didnt load' do
    expect { FBPi::MessageHandler.add_controller('nope') }
      .to raise_error(FBPi::MessageHandler::ControllerLoadErrorr)
  end
end
