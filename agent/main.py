import asyncio

from livekit import rtc
from livekit.agents import AutoSubscribe, JobContext, WorkerOptions, cli, llm
from livekit.agents.voice_assistant import VoiceAssistant
from livekit.plugins import openai, silero


# This function is the entrypoint for the agent.
async def entrypoint(ctx: JobContext):
    # Create an initial chat context with a system prompt
    initial_ctx = llm.ChatContext().append(
        role="system",
        text=(
            "You are a voice assistant created by LiveKit. Your interface with users will be voice. "
            "You should use short and concise responses, and avoiding usage of unpronouncable punctuation."
        ),
    )

    # Connect to the LiveKit room
    # indicating that the agent will only subscribe to audio tracks
    # await ctx.connect(auto_subscribe=AutoSubscribe.AUDIO_ONLY)
    await ctx.connect()

    # VoiceAssistant is a class that creates a full conversational AI agent.
    # See https://github.com/livekit/agents/tree/main/livekit-agents/livekit/agents/voice_assistant
    # for details on how it works.
    assistant = VoiceAssistant(
        vad=silero.VAD.load(),
        stt=openai.STT(base_url="http://127.0.0.1:8080/v1"),
        llm=openai.LLM(base_url="http://127.0.0.1:8080/v1", model="gpt-4"),
        tts=openai.TTS(base_url="http://127.0.0.1:8080/v1"),
        chat_ctx=initial_ctx,
    )

    # Start the voice assistant with the LiveKit room
    assistant.start(ctx.room)

    await asyncio.sleep(1)

    # listen to incoming chat messages, only required if you'd like the agent to
    # answer incoming messages from Chat
    chat = rtc.ChatManager(ctx.room)

    async def answer_from_text(txt: str):
        chat_ctx = assistant.chat_ctx.copy()
        chat_ctx.append(role="user", text=txt)
        stream = assistant.llm.chat(chat_ctx=chat_ctx)
        await assistant.say(stream)

    @chat.on("message_received")
    def on_chat_received(msg: rtc.ChatMessage):
        if msg.message:
            asyncio.create_task(answer_from_text(msg.message))

    # Greets the user with an initial message
    await assistant.say("Hey, how can I help you today?", allow_interruptions=True)


if __name__ == "__main__":
    # Initialize the worker with the entrypoint
    cli.run_app(WorkerOptions(entrypoint_fnc=entrypoint))