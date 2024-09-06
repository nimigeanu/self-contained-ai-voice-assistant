# Open-source self contained AI voice assistant

## Features
- Derived from [KITT](https://kitt.livekit.io/)
	- to see what you're getting into, click the link above and then `Connect`
- Unlike KITT, this does not rely on external services (i.e. self-contained)
- Unlike KITT, it only uses open-source components
	- [7B Hermes](https://huggingface.co/NousResearch/Hermes-2-Pro-Mistral-7B) for text generation (i.e. instead of commercial OpenAI)
	- [Piper](https://github.com/rhasspy/piper) for text-to-speech (i.e. instead of commercial ElevenLabs)
	- [Whisper](https://huggingface.co/openai/whisper-base) for speech-to-text (i.e. instead of commercial Deepgram)
- Runs in the cloud
- GPU accelerated (NVIDIA)
- Sets itself up with all required components
	- NVIDIA drivers
	- [LocalAI](https://localai.io/)
	- SSL certificates
	- [LiveKit server](https://github.com/livekit/livekit)
	- [LiveKit agent](https://github.com/livekit/agents)
	- Frontend, built on [agents playground](https://github.com/livekit/agents-playground/)

## Setup

### Deploying the stack
1. Sign in to the [AWS Management Console](https://aws.amazon.com/console)
2. You will need a domain that you can create new DNS entries for; if this is managed via Route53, create a [Hosted Zone](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingHostedZone.html) for it; othewise you'll have to manually create some A records in the end
3. click the button below to launch the CloudFormation template. Alternatively you can [download](template.yaml) the template and adjust it to your needs.

[![Launch Stack](https://cdn.rawgit.com/buildkite/cloudformation-launch-stack-button-svg/master/launch-stack.svg)](https://console.aws.amazon.com/cloudformation/home#/stacks/create/review?stackName=self-contained-ai-voice-assistant&templateURL=https://s3.amazonaws.com/lostshadow/self-contained-ai-voice-assistant/template.yaml)

4. Choose a name for your stack
5. Adjust the parameters:
	* `DomainName` - Replace with the domain name you have access to. The demo will be installed on a subdomain of this domain, named according to the stack name specified above
	* `InstanceType` - Server Instance Type. Larger instances will be able to accomodate more rooms and users
	* `IsRoute53Managed` - Set to yes if the domain is managed by Route53 and you have already created a [hosted zone](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingHostedZone.html) for it. Otherwise, change it to `no`


6. Check the `I acknowledge that AWS CloudFormation might create IAM resources` box. This confirms you agree to have some required IAM roles and policies created by CloudFormation.
7. Hit the `Create stack` button. 
8. Wait for the `Status` of your CloudFormation template to become `CREATE_COMPLETE`. Note that this may take **2-3 minutes** or more.
9. Check the `Outputs` section of your CloudFormation template. **ONLY** If you set `IsRoute53Managed` to `no`, you will find instructions to manually create two DNS records. Go ahead and create these records now.
10. Also under `Outputs`, click the `InitalizationProgressPageLink`. This should display a simple console-style box showing updated details on the process of initialization. Be patient watching this unfold or take a nice long break, it will take 20 minutes or more. When it eventually finished it should display something like `You may now connect to https://example.com` on the last line.
11. Also under `Outputs`, click the `VoiceAssistantLink`. This will open a page similar to KITT above.
12. Hit `Connect` in the upper right corner
13. Allow microphone access if requested.
14. Ask the assistant anything, speak or type in the chat.
15. That's it, enjoy!


### Customization
#### Frontend
The simplest UI to accomodate this is described [here](https://docs.livekit.io/agents/quickstart/#6-Create-the-UI)

#### Running other AI models
See [here](https://localai.io/docs/getting-started/models/)

#### Running without a GPU
In the cloud context, running models solely on CPUs requires virtual servers that are more expensive than those equipped with GPUs for performing the same tasks.
If you really want it see the `CPU example` [here](https://localai.io/basics/container/#usage)

#### Running locally
If you're on linux, adjust the script [here](./template.yaml#L315) and run it. The trickiest part will probably be setting up the GPU drivers.


## Notes
 - This demo uses a [forked livekit-agents implement](https://github.com/nimigeanu/livekit-agents). This was necessary in order to adapt to the fact that LocalAI's text-to-speech feature somehow only outputs PCM audio, even when other formats like MP3 are requested.
 - Do not hurry to click the `VoiceAssistantLink` (step 11 above), especially if you're creating the DNS entries manually; in some network environments an intermediate DNS may cache the NXDOMAIN (while the domain is not yet ready) and hold on to it for a long time, thus making it look like the record is invalid; waiting for it until the initialization is ready (step 10 above) should be enough for the records to settle, otherwise give it an extra 2-3 minutes