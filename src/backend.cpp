#include "backend.h"
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRandomGenerator>
#include <QSaveFile>
#include <QStandardPaths>

Backend::Backend(const QString &storage, QObject *parent) : QObject(parent),
    m_storage(storage.isEmpty() ? QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)+"/scores.json" : storage) {
    if(m_storage != ":memory:") {
        QFile file(m_storage);
        if(file.exists()) {
            if(file.open(QIODevice::ReadOnly))
                m_best=qMax(0,QJsonDocument::fromJson(file.readAll()).object().value("best").toInt());
            else m_error=tr("Could not read your high score.");
        }
    }
    m_timer.setTimerType(Qt::PreciseTimer);
    connect(&m_timer,&QTimer::timeout,this,&Backend::step);
    restart();
}
QVariantList Backend::segments() const {
    QVariantList result;
    for(const auto &p:m_snake) result.append(QVariantMap{{"x",p.x()},{"y",p.y()}});
    return result;
}
void Backend::restart() {
    m_timer.stop(); m_state="ready"; m_score=0; m_direction=0; m_queue.clear();
    m_snake={QPoint(14,12),QPoint(13,12),QPoint(12,12),QPoint(11,12),QPoint(10,12)};
    m_food=QPoint(20,12); emit changed();
}
void Backend::setDifficulty(int value) {
    if(m_state=="running" || m_state=="paused") return;
    m_difficulty=qBound(0,value,2); emit changed();
}
void Backend::setWrap(bool value) {
    if(m_state=="running" || m_state=="paused") return;
    m_wrap=value; emit changed();
}
void Backend::primaryAction() {
    if(m_state=="running") { pause(); return; }
    if(m_state=="over" || m_state=="won") restart();
    m_state="running"; m_timer.start(interval()); emit changed();
}
void Backend::pause() {
    if(m_state!="running") return;
    m_state="paused"; m_timer.stop(); emit changed();
}
void Backend::turn(int direction) {
    if(m_state!="running" || direction<0 || direction>3 || m_queue.size()>=2) return;
    const int last=m_queue.isEmpty()?m_direction:m_queue.last();
    if(direction==last || (direction+2)%4==last) return;
    m_queue.append(direction);
}
void Backend::placeFood() {
    QList<QPoint> free;
    for(int y=0;y<24;++y) for(int x=0;x<30;++x)
        if(!m_snake.contains(QPoint(x,y))) free.append(QPoint(x,y));
    if(free.isEmpty()) { finish(true); return; }
    m_food=free.at(QRandomGenerator::global()->bounded(free.size()));
}
void Backend::saveBest() {
    if(m_storage==":memory:") return;
    if(!QDir().mkpath(QFileInfo(m_storage).absolutePath())) {
        m_error=tr("Could not save your high score."); return;
    }
    QSaveFile file(m_storage); file.setDirectWriteFallback(false);
    const auto data=QJsonDocument(QJsonObject{{"best",m_best}}).toJson();
    if(!file.open(QIODevice::WriteOnly) || file.write(data)!=data.size() || !file.commit())
        m_error=tr("Could not save your high score.");
}
void Backend::finish(bool won) {
    m_timer.stop(); m_state=won?"won":"over";
}
void Backend::step() {
    if(m_state!="running") return;
    if(!m_queue.isEmpty()) m_direction=m_queue.takeFirst();
    const QPoint directions[]={QPoint(1,0),QPoint(0,1),QPoint(-1,0),QPoint(0,-1)};
    QPoint next=m_snake.first()+directions[m_direction];
    if(m_wrap) next=QPoint((next.x()+30)%30,(next.y()+24)%24);
    const bool eats=next==m_food;
    const int collision=m_snake.indexOf(next);
    if(next.x()<0 || next.x()>=30 || next.y()<0 || next.y()>=24 ||
       (collision>=0 && (eats || collision<m_snake.size()-1))) {
        finish(); emit changed(); return;
    }
    m_snake.prepend(next);
    if(eats) {
        m_score+=10;
        if(m_score>m_best) {m_best=m_score; saveBest();}
        placeFood(); emit ate();
        if(m_state=="running") m_timer.setInterval(interval());
    } else m_snake.removeLast();
    emit changed();
}
