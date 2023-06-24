using System;
using System.Linq;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ConvexHull2D : MonoBehaviour
{
    [SerializeField]
    private int _pointCount = 10;

    private List<Vector3> _pointsTransform = new List<Vector3>();
    private LineRenderer _lineRenderer = default;
    private MeshFilter _filter = default;
    private List<Vector3> _ConvexHull = new List<Vector3>();

    private void Awake()
    {
        _lineRenderer = GetComponent<LineRenderer>();
        _filter = GetComponent<MeshFilter>();
    }

    private void Start()
    {
        for (int i = 0; i < _pointCount; i++)
        {
            var temp = GameObject.CreatePrimitive(PrimitiveType.Sphere).transform;

            temp.position = new Vector3(UnityEngine.Random.Range(-10.0F, 10.0F), 0, UnityEngine.Random.Range(-10.0F, 10.0F));
            _pointsTransform.Add(temp.position);
        }

        _pointsTransform = _pointsTransform.OrderBy(x => x.x).ThenBy(x => x.z).ToList();

        _ConvexHull.Add(_pointsTransform[0]);
        _ConvexHull.Add(_pointsTransform[1]);
        _pointsTransform.RemoveAt(0);

        _pointsTransform = _pointsTransform.OrderBy(x => 
        {
            var temp = Vector3.Normalize(x - _ConvexHull[0]);
            return Mathf.Acos(Vector3.Dot(temp, Vector3.back));
        }).ToList();

        foreach (var point in _pointsTransform)
        {
            Debug.Log(point);
        }

        for (int i = 0; i < _pointsTransform.Count; i++)
        {
            _ConvexHull.Add (_pointsTransform[i]);
            var temp = _ConvexHull[_ConvexHull.Count - 3] - _ConvexHull[_ConvexHull.Count - 2];
            var temp2 = _ConvexHull[_ConvexHull.Count - 1] - _ConvexHull[_ConvexHull.Count - 2];

            while (Vector3.Cross(temp, temp2).y < 0)
            {
                _ConvexHull.RemoveAt(_ConvexHull.Count - 2);

                if (_ConvexHull.Count < 3) break;

                temp = _ConvexHull[_ConvexHull.Count - 3] - _ConvexHull[_ConvexHull.Count - 2];
                temp2 = _ConvexHull[_ConvexHull.Count - 1] - _ConvexHull[_ConvexHull.Count - 2];
            }
        }
        
        _lineRenderer.positionCount = _ConvexHull.Count;
        _lineRenderer.SetPositions(_ConvexHull.ToArray());

        Mesh mesh = new Mesh();
        mesh.SetVertices(_ConvexHull);
        List<int> triangles = new List<int>();

        for (int i = 1; i < _ConvexHull.Count - 1; i++)
        {
            triangles.Add(0);
            triangles.Add(i);
            triangles.Add(i + 1);
        }

        mesh.triangles = triangles.ToArray();

        _filter.mesh = mesh;
    }
}
