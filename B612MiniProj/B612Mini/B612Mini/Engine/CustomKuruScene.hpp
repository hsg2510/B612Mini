//
//  CustomKuruScene.hpp
//  B612Mini
//
//  Created by JohnHong on 2018. 5. 12..
//  Copyright © 2018년 Naver. All rights reserved.
//

#ifndef CustomKuruScene_hpp
#define CustomKuruScene_hpp

#include <stdio.h>
#include "gameplay.h"

using namespace gameplay;

namespace kuru
{
    class CustomKuruScene : public gameplay::Ref
    {
    public:
        static CustomKuruScene* create();
        
        CustomKuruScene();
        ~CustomKuruScene();
        void initialize();
        void update(float elapsedTime);
        void render(float elapsedTime);
        Node* addNodeWithModel(Model *model);
        
    private:
        Scene* mInternalScene;
        
        bool drawScene(Node* node);
    };
}


#endif /* CustomKuruScene_hpp */
