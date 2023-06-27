using UnityEditor.Experimental.GraphView;

public class ExampleNode : Node
{
    public ExampleNode()
    {
        title = "Example";

        // 入力用のポート
        var inputPort = Port.Create<Edge>(Orientation.Horizontal, Direction.Input, Port.Capacity.Single, typeof(float));
        inputPort.portName = "Input";
        inputContainer.Add(inputPort);

        var outputPort = Port.Create<Edge>(Orientation.Horizontal, Direction.Output, Port.Capacity.Single, typeof(float));
        outputPort.portName = "Value";
        outputContainer.Add(outputPort);
    }
}
