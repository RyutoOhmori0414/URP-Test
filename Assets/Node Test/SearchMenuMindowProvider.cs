using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.Experimental.GraphView;
using UnityEngine;
using UnityEngine.UIElements;

public class SearchMenuMindowProvider : ScriptableObject, ISearchWindowProvider
{
    private ExampleGraphView _graphView;
    private EditorWindow _editorWindow;

    List<SearchTreeEntry> ISearchWindowProvider.CreateSearchTree(SearchWindowContext context)
    {
        var entries = new List<SearchTreeEntry>();
        entries.Add(new SearchTreeGroupEntry(new GUIContent("Create Node")));

        entries.Add(new SearchTreeGroupEntry(new GUIContent("Example")) { level = 1});

        entries.Add(new SearchTreeEntry(new GUIContent(nameof(ValueNode))) { level = 2, userData = typeof(ValueNode) });
        entries.Add(new SearchTreeEntry(new GUIContent(nameof(AddNode))) { level = 2, userData = typeof(AddNode) });
        entries.Add(new SearchTreeEntry(new GUIContent(nameof(OutputNode))) { level = 2, userData = typeof(OutputNode) });

        return entries;
    }

    bool ISearchWindowProvider.OnSelectEntry(SearchTreeEntry SearchTreeEntry, SearchWindowContext context)
    {
        var type = SearchTreeEntry.userData as Type;
        var node = Activator.CreateInstance(type) as Node;

        var worldMousePosition = _editorWindow.rootVisualElement.ChangeCoordinatesTo(_editorWindow.rootVisualElement.parent, context.screenMousePosition - _editorWindow.position.position);
    }
}
