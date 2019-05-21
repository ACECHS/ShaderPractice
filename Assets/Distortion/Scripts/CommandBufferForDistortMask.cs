using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class CommandBufferForDistortMask : MonoBehaviour
{
    private CommandBuffer CB = null;
    private Renderer renderer = null;
    private Material material = null;
    private int maskID = 0;
    private void OnEnable()
    {
        Camera.main.depthTextureMode = DepthTextureMode.Depth;//让相机生成深度图，可在shader通过_CameraDepthTexture进行引用
        renderer = gameObject.GetComponent<Renderer>();//获取该物体渲染组件
        CB = new CommandBuffer();//生成commanbuffer对象
        maskID = Shader.PropertyToID("MaskTex");//获取着色器属性名称的唯一标识符，使用属性标识符比使用字符串传递效率更高
        CB.GetTemporaryRT(maskID, -2, -2);//生成临时纹理，并标识为上述标识符，-2表示分辨率为原相机1/2，-x表示为原相机1/x
        CB.SetRenderTarget(maskID);//将临时纹理设为该commandbuffer的渲染到纹理
        CB.ClearRenderTarget(true, true, Color.black);//对渲染对象纹理进行清屏处理，具体属性查看官网api
        //获取当前物体的材质来渲染他自己
        material = renderer.sharedMaterial;
        CB.DrawRenderer(renderer, material);
        CB.SetGlobalTexture("_MaskTex", maskID);//将该临时纹理既该commandbuffer的渲染到纹理设为全局纹理属性，shader通过_MaskTex来引用它
        Camera.main.AddCommandBuffer(CameraEvent.AfterForwardOpaque, CB);//将commandbuffer插入至CameraEvent.AfterForwardOpaque时1实行
    }
    private void OnDisable()
    {
        //进行commandbuffer的移除，临时纹理的释放
        Camera.main.AddCommandBuffer(CameraEvent.AfterForwardOpaque, CB);
        CB.ReleaseTemporaryRT(maskID);
        CB.Clear();
    }
}
