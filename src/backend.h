#pragma once
#include <QObject>
#include <QPoint>
#include <QTimer>
#include <QVariantList>
#include <QElapsedTimer>

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList segments READ segments NOTIFY changed)
    Q_PROPERTY(QPoint food READ food NOTIFY changed)
    Q_PROPERTY(QString state READ state NOTIFY changed)
    Q_PROPERTY(int direction READ direction NOTIFY changed)
    Q_PROPERTY(int score READ score NOTIFY changed)
    Q_PROPERTY(int best READ best NOTIFY changed)
    Q_PROPERTY(int level READ level NOTIFY changed)
    Q_PROPERTY(int interval READ interval NOTIFY changed)
    Q_PROPERTY(int difficulty READ difficulty WRITE setDifficulty NOTIFY changed)
    Q_PROPERTY(bool wrap READ wrap WRITE setWrap NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
public:
    explicit Backend(const QString &storage = {}, QObject *parent = nullptr);
    QVariantList segments() const;
    QPoint food() const { return m_food; }
    QString state() const { return m_state; }
    int direction() const { return m_direction; }
    int score() const { return m_score; }
    int best() const { return m_best; }
    int level() const { return 1+m_score/50; }
    int interval() const { return qMax(48, 170-m_difficulty*35-(level()-1)*7); }
    int difficulty() const { return m_difficulty; }
    bool wrap() const { return m_wrap; }
    QString error() const { return m_error; }
    void setDifficulty(int value);
    void setWrap(bool value);
    Q_INVOKABLE void primaryAction();
    Q_INVOKABLE void restart();
    Q_INVOKABLE void turn(int direction);
    Q_INVOKABLE void pause();
    Q_INVOKABLE void step();
signals:
    void changed();
    void ate();
private:
    friend class OmsnakeTests;
    void placeFood();
    void finish(bool won=false);
    void saveBest();
    QList<QPoint> m_snake;
    QList<int> m_queue;
    QPoint m_food;
    QTimer m_timer;
    QString m_state="ready", m_storage, m_error;
    int m_direction=0, m_score=0, m_best=0, m_difficulty=1;
    bool m_wrap=false;
};
