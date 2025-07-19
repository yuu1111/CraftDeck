using StreamDeckLib;
using StreamDeckLib.Messages;
using System;
using System.IO;
using System.Threading.Tasks;

namespace CraftDeck.StreamDeckPlugin
{
  [ActionUuid(Uuid="com.craftdeck.plugin.action.craftdeckaction")]
  public class MyPluginAction : BaseStreamDeckActionWithSettingsModel<Models.CounterSettingsModel>
  {
    private const string CommandFileName = "command.txt";
    private static readonly string CommandFilePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "CraftDeck", CommandFileName);

    public override async Task OnKeyUp(StreamDeckEventPayload args)
    {
      // Example: Write a command to the file
      // In a real scenario, you would get the command from the action's settings
      string commandToSend = "/craftdeck test"; 

      try
      {
        Directory.CreateDirectory(Path.GetDirectoryName(CommandFilePath));
        await File.WriteAllTextAsync(CommandFilePath, commandToSend);
        await Manager.ShowOkAsync(args.context); // Indicate success
      }
      catch (Exception ex)
      {
        await Manager.ShowAlertAsync(args.context); // Indicate failure
        Console.WriteLine($"Error writing command file: {ex.Message}");
      }
    }

    public override async Task OnDidReceiveSettings(StreamDeckEventPayload args)
    {
      await base.OnDidReceiveSettings(args);
      // Update UI based on settings if needed
    }

    public override async Task OnWillAppear(StreamDeckEventPayload args)
    {
      await base.OnWillAppear(args);
      // Set initial state or title if needed
    }
  }
}
