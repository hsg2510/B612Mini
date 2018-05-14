//
//  KuruScene.hpp
//  B612Mini
//
//  Created by JohnHong on 2018. 2. 21..
//  Copyright © 2018년 Naver. All rights reserved.
//

#ifndef KuruScene_hpp
#define KuruScene_hpp

#include <stdio.h>
#include "gameplay.h"

namespace kuru
{
    class KuruScene : public gameplay::Ref
    {
    public:
        KuruScene(float aAspectRatio, gameplay::Rectangle aViewport);
        void render(float aElapsedTime);
    protected:
        ~KuruScene();
        
    private:
        void init();
        bool drawScene(gameplay::Node* aNode);
        
        gameplay::Scene* mInternalScene = nullptr;
        float mAspectRatio = 0.5625; // 9 : 16
        gameplay::Rectangle mViewport = gameplay::Rectangle();
    };
}


#endif /* KuruScene_hpp */
