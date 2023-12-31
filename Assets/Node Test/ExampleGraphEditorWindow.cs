using UnityEditor;

public class ExampleGraphEditorWindow : EditorWindow
{
    [MenuItem("Window/ExampleGraphEditorWindow")]
    public static void Open()
    {
        GetWindow<ExampleGraphEditorWindow>(ObjectNames.NicifyVariableName(nameof(ExampleGraphEditorWindow)));
    }

    private void OnEnable()
    {
        var graphView = new ExampleGraphView(this);
        rootVisualElement.Add(graphView);
    }
}
