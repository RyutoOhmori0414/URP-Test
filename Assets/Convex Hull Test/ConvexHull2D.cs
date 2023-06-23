using System;
using System.Linq;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ConvexHull2D : MonoBehaviour
{
    [SerializeField]
    private int _pointCount = 10;

    private Transform[] _pointsTransform = default;
    private LineRenderer _lineRenderer = default;
    private List<Vector3> _ConvexHull = new List<Vector3>();

    private void Awake()
    {
        _lineRenderer = GetComponent<LineRenderer>();
    }

    private void Start()
    {
        _pointsTransform = new Transform[_pointCount];

        for (int i = 0; i < _pointCount; i++)
        {
            _pointsTransform[i] = GameObject.CreatePrimitive(PrimitiveType.Sphere).transform;

            _pointsTransform[i].position = new Vector3(UnityEngine.Random.Range(-10.0F, 10.0F), 0, UnityEngine.Random.Range(-10.0F, 10.0F));
        }

        _pointsTransform = _pointsTransform.OrderBy(x => x.position.x).ThenBy(x => x.position.z).ToArray();

        _ConvexHull.Add(_pointsTransform[0].position);

        for (int i = 0; i < _pointsTransform.Length; i++)
        {
            for (int j = 0; j < _pointsTransform.Length; j++)
            {
                if (i == j) continue;
            }
        }
        
        _lineRenderer.positionCount = _ConvexHull.Count;
        _lineRenderer.SetPositions(_ConvexHull.ToArray());
    }
}
